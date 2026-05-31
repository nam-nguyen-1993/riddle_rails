class AddMixedQuestionsToGames < ActiveRecord::Migration[8.0]
  def change
    add_column :games, :mixed_questions, :boolean, null: false, default: false
    add_index :games, :mixed_questions
  end
end
