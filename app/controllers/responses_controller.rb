class ResponsesController < ApplicationController
  before_action :set_game
  before_action :require_active_game

  def create
    question = @game.current_question
    player = @game.current_player

    if question.blank? || player.blank?
      @game.complete!
      redirect_to @game
      return
    end

    @game.responses.create!(
      player: player,
      question: question,
      answer_choice_id: response_params[:answer_choice_id],
      time_taken_seconds: response_params[:time_taken_seconds]
    )

    player_turn_complete = @game.player_turn_complete?
    @game.complete! if @game.complete_round?
    redirect_path = player_turn_complete ? game_path(@game, turn_complete: player.id) : game_path(@game)

    respond_to do |format|
      format.html { redirect_to redirect_path }
      format.turbo_stream { redirect_to redirect_path }
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    redirect_to @game
  end

  private

  def set_game
    @game = current_user.games.find(params[:game_id])
  end

  def require_active_game
    redirect_to @game unless @game.active?
  end

  def response_params
    params.fetch(:response, {}).permit(:answer_choice_id, :time_taken_seconds)
  end
end
