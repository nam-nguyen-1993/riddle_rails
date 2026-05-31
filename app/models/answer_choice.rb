# == Schema Information
#
# Table name: answer_choices
#
#  id          :bigint           not null, primary key
#  body        :text             not null
#  correct     :boolean          default(FALSE), not null
#  position    :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  question_id :bigint           not null
#
# Indexes
#
#  index_answer_choices_on_question_id               (question_id)
#  index_answer_choices_on_question_id_and_correct   (question_id,correct)
#  index_answer_choices_on_question_id_and_position  (question_id,position) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (question_id => questions.id)
#
class AnswerChoice < ApplicationRecord
  belongs_to :question

  scope :correct, -> { where(correct: true) }
  scope :ordered, -> { order(:position) }

  validates :body, presence: true
  validates :position, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :position, uniqueness: { scope: :question_id }
end
