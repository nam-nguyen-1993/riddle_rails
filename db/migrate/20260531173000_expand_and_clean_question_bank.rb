class ExpandAndCleanQuestionBank < ActiveRecord::Migration[8.0]
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
    remove_prefixed_starter_questions!

    topics_by_name = SeedTopic.where(name: TOPIC_DESCRIPTIONS.keys).index_by(&:name)
    seed_entries = clean_entries(questions_file)
    prompts = seed_entries.map { |entry| entry["clean_prompt"] }
    topic_ids = seed_entries.filter_map { |entry| topics_by_name[entry["topic"]]&.id }.uniq
    existing_question_keys = SeedQuestion
      .where(topic_id: topic_ids, prompt: prompts)
      .pluck(:topic_id, :prompt)
      .to_set

    question_rows = seed_entries.filter_map do |entry|
      topic = topics_by_name[entry["topic"]]
      next unless topic
      next if existing_question_keys.include?([topic.id, entry["clean_prompt"]])

      {
        topic_id: topic.id,
        prompt: entry["clean_prompt"],
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

    questions_by_key = SeedQuestion
      .where(topic_id: topic_ids, prompt: prompts)
      .pluck(:topic_id, :prompt, :id)
      .to_h { |topic_id, prompt, question_id| [[topic_id, prompt], question_id] }
    existing_choice_pairs = SeedAnswerChoice
      .where(question_id: questions_by_key.values)
      .pluck(:question_id, :position)
      .to_set

    choice_rows = seed_entries.flat_map do |entry|
      topic = topics_by_name[entry["topic"]]
      next [] unless topic

      question_id = questions_by_key[[topic.id, entry["clean_prompt"]]]
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
    # Keep the larger clean bank if this migration is rolled back.
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

  def remove_prefixed_starter_questions!
    question_ids = SeedQuestion
      .where("prompt LIKE ?", "Starter bank %")
      .or(SeedQuestion.where("prompt LIKE ?", "Seed bank %"))
      .pluck(:id)

    SeedAnswerChoice.where(question_id: question_ids).delete_all
    SeedQuestion.where(id: question_ids).delete_all
  end

  def clean_entries(questions_file)
    JSON
      .parse(File.read(questions_file))
      .group_by { |question_data| question_data.fetch("topic") }
      .flat_map do |_topic_name, questions|
        questions
          .uniq { |question_data| clean_prompt(question_data.fetch("prompt")) }
          .map { |question_data| question_data.merge("clean_prompt" => clean_prompt(question_data.fetch("prompt"))) }
      end
  end

  def clean_prompt(prompt)
    prompt
      .to_s
      .sub(/\AStarter bank [^:]+ \d+:\s*/, "")
      .sub(/\ASeed bank \d+:\s*/, "")
      .sub(/\A[^:]+ bank \d+:\s*/, "")
      .strip
  end
end
