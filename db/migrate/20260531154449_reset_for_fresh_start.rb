class ResetForFreshStart < ActiveRecord::Migration[8.0]
  def up
    # Delete in FK-safe order (children before parents)
    execute "DELETE FROM responses"
    execute "DELETE FROM game_questions"
    execute "DELETE FROM players"
    execute "DELETE FROM games"
    execute "DELETE FROM answer_choices"
    execute "DELETE FROM questions"
    execute "DELETE FROM topics"
  end

  def down
    # Irreversible — intentional one-time reset
  end
end
