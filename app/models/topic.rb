# == Schema Information
#
# Table name: topics
#
#  id          :bigint           not null, primary key
#  active      :boolean          default(TRUE), not null
#  description :text
#  name        :string           not null
#  position    :integer          default(0), not null
#  slug        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_topics_on_active_and_position  (active,position)
#  index_topics_on_name                 (name) UNIQUE
#  index_topics_on_slug                 (slug) UNIQUE
#
class Topic < ApplicationRecord
  has_many :questions, -> { order(created_at: :desc) }, dependent: :destroy
  has_many :active_questions, -> { active.order(created_at: :desc) }, class_name: "Question", inverse_of: :topic
  has_many :games, dependent: :restrict_with_exception

  before_validation :set_slug

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :name) }

  validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 100 }
  validates :slug, presence: true, uniqueness: true

  private

  def set_slug
    self.slug = name.to_s.parameterize if slug.blank?
  end
end
