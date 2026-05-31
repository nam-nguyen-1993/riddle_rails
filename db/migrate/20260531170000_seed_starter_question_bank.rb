class SeedStarterQuestionBank < ActiveRecord::Migration[8.0]
  class SeedTopic < ActiveRecord::Base
    self.table_name = "topics"
  end

  class SeedQuestion < ActiveRecord::Base
    self.table_name = "questions"
  end

  class SeedAnswerChoice < ActiveRecord::Base
    self.table_name = "answer_choices"
  end

  TOPIC_DESCRIPTIONS = {
    "Math" => "Numbers, shapes, and patterns",
    "Nature" => "Plants, seasons, weather, and the outdoors",
    "History" => "People and events from the past",
    "Science" => "Everyday science for curious kids",
    "Riddles" => "Wordplay and thinking puzzles",
    "Geography" => "Places, maps, and the world",
    "Animals" => "Creatures big and small",
    "Trading Card Trivia" => "General creature-card ideas without brand names",
    "Dinosaurs" => "Prehistoric creatures and the world they lived in",
    "Oceans" => "Seas, marine life, and ocean science"
  }.freeze

  def up
    questions_file = Rails.root.join("db/seeds/questions.json")
    return unless File.exist?(questions_file)

    require "json"
    require "set"

    now = Time.current
    seed_topics!(now)

    topics_by_name = SeedTopic.where(name: TOPIC_DESCRIPTIONS.keys).index_by(&:name)
    seed_entries = starter_entries(questions_file)
    seed_prompts = seed_entries.map { |entry| entry["seed_prompt"] }
    existing_prompts = SeedQuestion.where(prompt: seed_prompts).pluck(:prompt).to_set

    question_rows = seed_entries.filter_map do |entry|
      next if existing_prompts.include?(entry["seed_prompt"])

      topic = topics_by_name[entry["topic"]]
      next unless topic

      {
        topic_id: topic.id,
        prompt: entry["seed_prompt"],
        explanation: entry["explanation"],
        difficulty: entry["difficulty"] || "easy",
        age_min: entry["age_min"] || 7,
        age_max: entry["age_max"] || 10,
        question_format: "multiple_choice",
        active: true,
        created_at: now,
        updated_at: now
      }
    end

    SeedQuestion.insert_all(question_rows) if question_rows.any?

    questions_by_prompt = SeedQuestion.where(prompt: seed_prompts).pluck(:prompt, :id).to_h
    existing_choice_pairs = SeedAnswerChoice
      .where(question_id: questions_by_prompt.values)
      .pluck(:question_id, :position)
      .to_set

    choice_rows = seed_entries.flat_map do |entry|
      question_id = questions_by_prompt[entry["seed_prompt"]]
      next [] unless question_id

      entry["choices"].each_with_index.filter_map do |choice, index|
        position = choice["position"] || index + 1
        next if existing_choice_pairs.include?([question_id, position])

        {
          question_id: question_id,
          body: choice["body"],
          correct: choice["correct"],
          position: position,
          created_at: now,
          updated_at: now
        }
      end
    end

    choice_rows.each_slice(1000) { |batch| SeedAnswerChoice.insert_all(batch) }
  end

  def down
    question_ids = SeedQuestion.where("prompt LIKE ?", "Starter bank %").pluck(:id)
    SeedAnswerChoice.where(question_id: question_ids).delete_all
    SeedQuestion.where(id: question_ids).delete_all
  end

  private

  def seed_topics!(now)
    TOPIC_DESCRIPTIONS.each.with_index(1) do |(name, description), position|
      SeedTopic.find_or_create_by!(name: name) do |topic|
        topic.description = description
        topic.position = position
        topic.active = true
        topic.slug = name.parameterize
        topic.created_at = now
        topic.updated_at = now
      end
    end
  end

  def starter_entries(questions_file)
    JSON
      .parse(File.read(questions_file))
      .group_by { |question_data| question_data.fetch("topic") }
      .flat_map do |topic_name, questions|
        questions.first(50).each_with_index.map do |question_data, index|
          question_data.merge("seed_prompt" => "Starter bank #{topic_name} #{index + 1}: #{question_data.fetch("prompt")}")
        end
      end
  end
end
