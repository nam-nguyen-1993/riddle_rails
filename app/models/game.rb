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
  has_many :standings, -> { order(score: :desc, position: :asc) }, class_name: "Player", inverse_of: :game

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
    players.count * game_questions.count
  end

  def current_game_question
    return nil if completed? || game_questions.empty?

    game_questions.offset(current_question_index).first
  end

  def current_question
    current_game_question&.question
  end

  def current_player
    return nil if players.empty?

    players.offset(current_player_index).first
  end

  def progress_label
    "#{[current_question_index + 1, game_questions.count].min} of #{game_questions.count}"
  end

  def current_player_round_label
    "#{[current_player_index + 1, players.count].min} of #{players.count}"
  end

  def complete_round?
    total_turn_count.positive? && responses.count >= total_turn_count
  end

  def player_turn_complete?
    game_questions.count.positive? && (responses.count % game_questions.count).zero?
  end

  def select_questions!(questions: nil)
    source = questions&.first(question_count) || recency_weighted_questions.limit(question_count).to_a
    source.each.with_index(1) do |question, position|
      game_questions.create!(question: question, position: position)
    end
  end

  def top_players
    highest_score = players.maximum(:score)
    return Player.none if highest_score.blank?

    players.where(score: highest_score).order(:position)
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

    current_turn_index % game_questions.count
  end

  def current_player_index
    return 0 if game_questions.empty?

    current_turn_index / game_questions.count
  end

  def question_pool
    if mixed_questions?
      Question.active
    else
      topic.active_questions
    end
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
