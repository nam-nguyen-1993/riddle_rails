# == Schema Information
#
# Table name: games
#
#  id               :bigint           not null, primary key
#  ended_at         :datetime
#  mixed_questions  :boolean          default(FALSE), not null
#  question_count   :integer          default(10), not null
#  seconds_per_turn :integer          default(40), not null
#  started_at       :datetime
#  status           :string           default("setup"), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  topic_id         :bigint           not null
#  user_id          :bigint           not null
#
# Indexes
#
#  index_games_on_mixed_questions          (mixed_questions)
#  index_games_on_topic_id                 (topic_id)
#  index_games_on_topic_id_and_created_at  (topic_id,created_at)
#  index_games_on_user_id                  (user_id)
#  index_games_on_user_id_and_status       (user_id,status)
#
# Foreign Keys
#
#  fk_rails_...  (topic_id => topics.id)
#  fk_rails_...  (user_id => users.id)
#
class Game < ApplicationRecord
  STATUSES = %w[setup active completed abandoned].freeze
  MAX_PLAYERS = 4

  belongs_to :user
  belongs_to :topic

  has_many :players, -> { order(:position) }, dependent: :destroy, inverse_of: :game
  has_many :game_questions, -> { order(:position) }, dependent: :destroy, inverse_of: :game
  has_many :questions, through: :game_questions
  has_many :responses, dependent: :destroy
  has_many :standings, -> { by_score }, class_name: "Player", inverse_of: :game

  accepts_nested_attributes_for :players, allow_destroy: true

  scope :recent, -> { order(created_at: :desc) }
  scope :in_progress, -> { where(status: "active") }
  scope :finished, -> { where(status: "completed") }

  validates :status, inclusion: { in: STATUSES }
  validates :question_count, numericality: { only_integer: true, greater_than: 0 }
  validates :seconds_per_turn, numericality: { only_integer: true, greater_than: 0 }
  validate :player_limit

  def complete!
    update!(status: "completed", ended_at: Time.current)
  end

  def start!
    update!(status: "active", started_at: Time.current)
  end

  def completed?
    status == "completed"
  end

  def active?
    status == "active"
  end

  def current_turn_index
    responses.count
  end

  def total_turn_count
    players.size * game_questions.size
  end

  def current_game_question
    return nil if completed? || game_questions.empty?

    if game_questions.loaded?
      game_questions.to_a[current_question_index]
    else
      game_questions.offset(current_question_index).first
    end
  end

  def current_question
    current_game_question&.question
  end

  def current_player
    return nil if players.empty?

    if players.loaded?
      players.to_a[current_player_index]
    else
      players.offset(current_player_index).first
    end
  end

  def progress_label
    "#{current_question_index + 1} of #{game_questions.size}"
  end

  def current_player_round_label
    "#{current_player_index + 1} of #{players.size}"
  end

  def complete_round?
    total = total_turn_count
    total.positive? && responses.count >= total
  end

  def player_turn_complete?
    game_questions.size.positive? && (responses.count % game_questions.size).zero?
  end

  def topic_label
    mixed_questions? ? "Mixed questions" : topic.name
  end

  def select_questions!(questions: nil)
    source = if questions.present?
      questions.first(question_count)
    elsif mixed_questions?
      topic_varied_questions
    else
      recency_weighted_questions.limit(question_count).to_a
    end
    source.each.with_index(1) do |question, position|
      game_questions.create!(question: question, position: position)
    end
  end

  def top_players
    @top_players ||= begin
      highest_score = players.maximum(:score)
      highest_score.blank? ? Player.none : players.where(score: highest_score)
    end
  end

  def tied?
    top_players.size > 1
  end

  def winner
    return nil if tied?

    top_players.first
  end

  def result_summary
    return status.titleize unless completed?
    return "Tie: #{top_players.map(&:name).to_sentence}" if tied?

    "#{winner&.name} won"
  end

  private

  def current_question_index
    return 0 if game_questions.empty?

    current_turn_index % game_questions.size
  end

  def current_player_index
    return 0 if game_questions.empty?

    current_turn_index / game_questions.size
  end

  def question_pool
    if mixed_questions?
      Question.active
    else
      topic.active_questions
    end
  end

  def topic_varied_questions
    # Pull a large pool ordered by recency, then round-robin by topic
    # so mixed games always have maximum variety (max 2 per topic).
    pool = recency_weighted_questions.limit(question_count * 4).to_a
    by_topic = pool.group_by(&:topic_id).values.shuffle

    result = []
    (1..2).each do |pass|
      by_topic.each do |topic_qs|
        result << topic_qs[pass - 1] if topic_qs.size >= pass && result.size < question_count
      end
      break if result.size >= question_count
    end

    result.shuffle.first(question_count)
  end

  def recency_weighted_questions
    last_played_sql = Response
      .where(game_id: Game.where(user_id: user_id).select(:id))
      .where("responses.question_id = questions.id")
      .select("MAX(responses.answered_at)")
      .to_sql

    question_pool
      .unscope(:order)
      .multiple_choice
      .order(Arel.sql("(#{last_played_sql}) ASC NULLS FIRST, RANDOM()"))
  end

  def player_limit
    return if players.reject(&:marked_for_destruction?).size <= MAX_PLAYERS

    errors.add(:players, "cannot be more than #{MAX_PLAYERS}")
  end
end
