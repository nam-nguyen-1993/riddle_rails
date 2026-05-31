# == Schema Information
#
# Table name: questions
#
#  id              :bigint           not null, primary key
#  active          :boolean          default(TRUE), not null
#  age_max         :integer          default(10), not null
#  age_min         :integer          default(7), not null
#  difficulty      :string           default("easy"), not null
#  explanation     :text
#  prompt          :text             not null
#  question_format :string           default("multiple_choice"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  topic_id        :bigint           not null
#
# Indexes
#
#  index_questions_on_topic_id                 (topic_id)
#  index_questions_on_topic_id_and_active      (topic_id,active)
#  index_questions_on_topic_id_and_difficulty  (topic_id,difficulty)
#
# Foreign Keys
#
#  fk_rails_...  (topic_id => topics.id)
#
class Question < ApplicationRecord
  FORMATS = %w[multiple_choice].freeze
  DIFFICULTIES = %w[easy medium hard].freeze

  belongs_to :topic

  has_many :answer_choices, -> { order(:position) }, dependent: :destroy, inverse_of: :question
  has_many :correct_answer_choices, -> { where(correct: true).order(:position) }, class_name: "AnswerChoice", inverse_of: :question
  has_many :game_questions, dependent: :destroy
  has_many :games, through: :game_questions
  has_many :responses, dependent: :restrict_with_exception

  accepts_nested_attributes_for :answer_choices, allow_destroy: true

  scope :active, -> { where(active: true) }
  scope :multiple_choice, -> { where(question_format: "multiple_choice") }
  scope :for_age, ->(age) { where("age_min <= ? AND age_max >= ?", age, age) }
  scope :unplayed_by, ->(user) { where.not(id: user.played_questions.select(:id)) }

  validates :prompt, presence: true
  validates :question_format, inclusion: { in: FORMATS }
  validates :difficulty, inclusion: { in: DIFFICULTIES }
  validates :age_min, :age_max, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :age_range_is_valid
  validate :multiple_choice_has_correct_answer

  def correct_answer_choice
    correct_answer_choices.first
  end

  private

  def age_range_is_valid
    return if age_min.blank? || age_max.blank? || age_min <= age_max

    errors.add(:age_min, "must be less than or equal to age max")
  end

  def multiple_choice_has_correct_answer
    return unless question_format == "multiple_choice"
    return if answer_choices.any?(&:correct?)

    errors.add(:answer_choices, "must include at least one correct answer")
  end
end
