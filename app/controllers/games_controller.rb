class GamesController < ApplicationController
  before_action :set_game, only: :show
  before_action :require_non_setup_game, only: :show

  def new
    @topics = Topic.active.ordered
    @game = current_user.games.new(
      topic: @topics.first,
      mixed_questions: true,
      question_count: 10,
      seconds_per_turn: 40
    )
  end

  def create
    @topics = Topic.active.ordered
    player_names = normalized_player_names

    @game = current_user.games.new(game_params.except(:topic_id, :mixed_questions))
    player_names.each.with_index(1) do |name, position|
      @game.players.build(name: name, position: position)
    end

    if player_names.empty?
      @game.errors.add(:players, "add at least one player")
      render :new, status: :unprocessable_entity
      return
    end

    ActiveRecord::Base.transaction do
      configure_question_source
      @game.save!
      select_game_questions!

      if @game.game_questions.empty?
        @game.errors.add(:base, "Add questions for this topic before starting a game.")
        raise ActiveRecord::Rollback
      end

      @game.start!
    end

    if @game.persisted? && @game.active?
      redirect_to @game
    else
      render :new, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordInvalid => e
    @game.errors.add(:base, e.message)
    render :new, status: :unprocessable_entity
  end

  def show
    @current_question = @game.current_question
    @current_player = @game.current_player
    @completed_player = @game.players.find_by(id: params[:turn_complete])
    @response = @game.responses.new
    @responses_by_player_and_question = @game.responses.includes(:answer_choice).index_by do |response|
      [response.player_id, response.question_id]
    end
    @previous_played_at_by_question = previous_played_at_by_question if @game.completed?
  end

  private

  def set_game
    @game = current_user.games.includes(:topic, :players, game_questions: { question: :answer_choices }).find(params[:id])
  end

  def require_non_setup_game
    redirect_to new_game_path if @game.status == "setup"
  end

  def game_params
    params.require(:game).permit(:topic_id, :question_count, :seconds_per_turn, :mixed_questions)
  end

  def normalized_player_names
    Array(params.dig(:game, :player_names))
      .map { |name| name.to_s.strip }
      .reject(&:blank?)
      .first(Game::MAX_PLAYERS)
  end

  def configure_question_source
    case question_source
    when "mixed"
      @game.topic = @topics.first
      @game.mixed_questions = true
    when "custom"
      topic_id = params.dig(:game, :pregenerated_topic_id).to_i
      if topic_id.zero?
        @game.errors.add(:base, "Confirm your AI topic before starting the game.")
        raise ActiveRecord::Rollback
      end

      topic = Topic.find_by(id: topic_id)
      unless topic
        @game.errors.add(:base, "Topic not found. Please confirm your AI topic again.")
        raise ActiveRecord::Rollback
      end

      @pregenerated_question_ids = params.dig(:game, :question_ids).to_s.split(",").map(&:to_i)
      @game.topic = topic
      @game.mixed_questions = false
    else
      @game.topic = @topics.find { |t| t.id == game_params[:topic_id].to_i } || @topics.first
      @game.mixed_questions = false
    end
  end

  def select_game_questions!
    if @pregenerated_question_ids.present?
      questions = Question.active.where(id: @pregenerated_question_ids).to_a
      @game.select_questions!(questions: questions)
    else
      @game.select_questions!
    end
  end

  def question_source
    params.dig(:game, :question_source).presence_in(%w[mixed specific custom]) || "mixed"
  end

  def previous_played_at_by_question
    Response
      .joins(:game)
      .where(games: { user_id: current_user.id })
      .where.not(game_id: @game.id)
      .where(question_id: @game.questions.select(:id))
      .group(:question_id)
      .maximum(:answered_at)
  end
end
