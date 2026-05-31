# == Schema Information
#
# Table name: game_questions
#
#  id          :bigint           not null, primary key
#  position    :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  game_id     :bigint           not null
#  question_id :bigint           not null
#
# Indexes
#
#  index_game_questions_on_game_id                  (game_id)
#  index_game_questions_on_game_id_and_position     (game_id,position) UNIQUE
#  index_game_questions_on_game_id_and_question_id  (game_id,question_id) UNIQUE
#  index_game_questions_on_question_id              (question_id)
#
# Foreign Keys
#
#  fk_rails_...  (game_id => games.id)
#  fk_rails_...  (question_id => questions.id)
#
class GameQuestion < ApplicationRecord
  belongs_to :game
  belongs_to :question

  scope :ordered, -> { order(:position) }

  validates :position, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :position, uniqueness: { scope: :game_id }
  validates :question_id, uniqueness: { scope: :game_id }
end
