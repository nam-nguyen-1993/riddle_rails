# == Schema Information
#
# Table name: players
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  position   :integer          not null
#  score      :integer          default(0), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  game_id    :bigint           not null
#
# Indexes
#
#  index_players_on_game_id               (game_id)
#  index_players_on_game_id_and_position  (game_id,position) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (game_id => games.id)
#
class Player < ApplicationRecord
  belongs_to :game

  has_many :responses, dependent: :destroy

  scope :ordered, -> { order(:position) }
  scope :by_score, -> { order(score: :desc, position: :asc) }

  validates :name, presence: true
  validates :position, presence: true, numericality: { only_integer: true, in: 1..Game::MAX_PLAYERS }
  validates :position, uniqueness: { scope: :game_id }
  validates :score, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
