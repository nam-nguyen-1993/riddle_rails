# == Schema Information
#
# Table name: responses
#
#  id                 :bigint           not null, primary key
#  answered_at        :datetime
#  correct            :boolean          default(FALSE), not null
#  time_taken_seconds :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  answer_choice_id   :bigint
#  game_id            :bigint           not null
#  player_id          :bigint           not null
#  question_id        :bigint           not null
#
# Indexes
#
#  index_responses_on_answer_choice_id                       (answer_choice_id)
#  index_responses_on_game_id                                (game_id)
#  index_responses_on_game_id_and_player_id_and_question_id  (game_id,player_id,question_id) UNIQUE
#  index_responses_on_game_id_and_question_id                (game_id,question_id)
#  index_responses_on_player_id                              (player_id)
#  index_responses_on_player_id_and_correct                  (player_id,correct)
#  index_responses_on_question_id                            (question_id)
#
# Foreign Keys
#
#  fk_rails_...  (answer_choice_id => answer_choices.id)
#  fk_rails_...  (game_id => games.id)
#  fk_rails_...  (player_id => players.id)
#  fk_rails_...  (question_id => questions.id)
#
class Response < ApplicationRecord
  belongs_to :game
  belongs_to :player
  belongs_to :question
  belongs_to :answer_choice, optional: true

  before_validation :set_answered_at
  before_validation :set_correctness
  after_create :award_point

  scope :correct, -> { where(correct: true) }
  scope :answered, -> { where.not(answered_at: nil) }

  validates :question_id, uniqueness: { scope: [:game_id, :player_id] }
  validates :time_taken_seconds, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 300 }, allow_nil: true
  validate :player_belongs_to_game
  validate :question_belongs_to_game
  validate :answer_choice_belongs_to_question

  private

  def set_answered_at
    self.answered_at ||= Time.current
  end

  def set_correctness
    self.correct = answer_choice&.correct? || false
  end

  def award_point
    player.increment!(:score) if correct?
  end

  def player_belongs_to_game
    return if player.blank? || game.blank? || player.game_id == game.id

    errors.add(:player, "must belong to the same game")
  end

  def question_belongs_to_game
    return if question.blank? || game.blank? || game.questions.exists?(question.id)

    errors.add(:question, "must be part of the game")
  end

  def answer_choice_belongs_to_question
    return if answer_choice.blank? || question.blank? || answer_choice.question_id == question.id

    errors.add(:answer_choice, "must belong to the selected question")
  end
end
