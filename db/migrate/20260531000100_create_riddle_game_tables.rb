class CreateRiddleGameTables < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email, null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :reset_password_token, unique: true

    create_table :topics do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.boolean :active, null: false, default: true
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :topics, :name, unique: true
    add_index :topics, :slug, unique: true
    add_index :topics, [:active, :position]

    create_table :questions do |t|
      t.references :topic, null: false, foreign_key: true
      t.text :prompt, null: false
      t.string :question_format, null: false, default: "multiple_choice"
      t.string :difficulty, null: false, default: "easy"
      t.integer :age_min, null: false, default: 7
      t.integer :age_max, null: false, default: 10
      t.text :explanation
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :questions, [:topic_id, :active]
    add_index :questions, [:topic_id, :difficulty]
    add_check_constraint :questions, "age_min <= age_max", name: "questions_age_range_check"

    create_table :answer_choices do |t|
      t.references :question, null: false, foreign_key: true
      t.text :body, null: false
      t.boolean :correct, null: false, default: false
      t.integer :position, null: false

      t.timestamps
    end

    add_index :answer_choices, [:question_id, :position], unique: true
    add_index :answer_choices, [:question_id, :correct]

    create_table :games do |t|
      t.references :user, null: false, foreign_key: true
      t.references :topic, null: false, foreign_key: true
      t.string :status, null: false, default: "setup"
      t.integer :question_count, null: false, default: 10
      t.integer :seconds_per_turn, null: false, default: 40
      t.datetime :started_at
      t.datetime :ended_at

      t.timestamps
    end

    add_index :games, [:user_id, :status]
    add_index :games, [:topic_id, :created_at]

    create_table :players do |t|
      t.references :game, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :position, null: false
      t.integer :score, null: false, default: 0

      t.timestamps
    end

    add_index :players, [:game_id, :position], unique: true

    create_table :game_questions do |t|
      t.references :game, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.integer :position, null: false

      t.timestamps
    end

    add_index :game_questions, [:game_id, :position], unique: true
    add_index :game_questions, [:game_id, :question_id], unique: true

    create_table :responses do |t|
      t.references :game, null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.references :answer_choice, null: true, foreign_key: true
      t.boolean :correct, null: false, default: false
      t.integer :time_taken_seconds
      t.datetime :answered_at

      t.timestamps
    end

    add_index :responses, [:game_id, :player_id, :question_id], unique: true
    add_index :responses, [:game_id, :question_id]
    add_index :responses, [:player_id, :correct]
  end
end
