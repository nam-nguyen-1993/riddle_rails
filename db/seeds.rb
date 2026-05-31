require "json"
require "set"

# ── Demo user ──────────────────────────────────────────────────────────────
user = User.find_or_initialize_by(email: "parent@example.com")
if user.encrypted_password.blank?
  user.password = "password"
  user.password_confirmation = "password"
end
user.save!

# ── Topics ─────────────────────────────────────────────────────────────────
[
  ["Math",               "Numbers, shapes, and patterns"],
  ["Nature",             "Plants, seasons, weather, and the outdoors"],
  ["History",            "People and events from the past"],
  ["Science",            "Everyday science for curious kids"],
  ["Riddles",            "Wordplay and thinking puzzles"],
  ["Geography",          "Places, maps, and the world"],
  ["Animals",            "Creatures big and small"],
  ["Trading Card Trivia","General creature-card ideas without brand names"],
  ["Dinosaurs",          "Prehistoric creatures and the world they lived in"],
  ["Oceans",             "Seas, marine life, and ocean science"]
].each.with_index(1) do |(name, description), position|
  Topic.find_or_create_by!(name: name) do |t|
    t.description = description
    t.position    = position
    t.active      = true
  end
end

# Question bank (bulk insert from questions.json)
questions_file = Rails.root.join("db/seeds/questions.json")

unless File.exist?(questions_file)
  puts "questions.json not found — skipping question import."
  return
end

data = JSON.parse(File.read(questions_file))
seed_entries = data.each_with_index.map do |question_data, index|
  question_data.merge("seed_prompt" => "Seed bank #{index + 1}: #{question_data.fetch("prompt")}")
end
seed_prompts = seed_entries.map { |question_data| question_data["seed_prompt"] }

now = Time.current
topics_by_name = Topic.all.index_by(&:name)
existing_prompts = Question.where(prompt: seed_prompts).pluck(:prompt).to_set

# 1. Bulk-insert questions. The JSON has repeated prompt text, so each row
# gets a stable seed prefix and can be looked up unambiguously later.
question_rows = seed_entries.filter_map do |q|
  next if existing_prompts.include?(q["seed_prompt"])

  topic = topics_by_name[q["topic"]]
  next unless topic

  {
    topic_id:        topic.id,
    prompt:          q["seed_prompt"],
    explanation:     q["explanation"],
    difficulty:      q["difficulty"] || "easy",
    age_min:         q["age_min"]    || 7,
    age_max:         q["age_max"]    || 10,
    question_format: "multiple_choice",
    active:          true,
    created_at:      now,
    updated_at:      now
  }
end

Question.insert_all(question_rows) if question_rows.any?

# 2. Fetch inserted IDs by the stable seed prompt.
id_map = Question.where(prompt: seed_prompts).pluck(:prompt, :id).to_h
existing_choice_pairs = AnswerChoice
  .where(question_id: id_map.values)
  .pluck(:question_id, :position)
  .to_set

# 3. Bulk-insert missing answer choices. This can repair a partial seed where
# questions were inserted but choices failed on a previous deploy.
choice_rows = seed_entries.flat_map do |q|
  qid = id_map[q["seed_prompt"]]
  next [] unless qid

  q["choices"].each_with_index.filter_map do |c, index|
    position = c["position"] || index + 1
    next if existing_choice_pairs.include?([qid, position])

    {
      question_id: qid,
      body:        c["body"],
      correct:     c["correct"],
      position:    position,
      created_at:  now,
      updated_at:  now
    }
  end
end

choice_rows.each_slice(1000) { |batch| AnswerChoice.insert_all(batch) }

puts "Seeded #{question_rows.size} new questions and #{choice_rows.size} new answer choices. Totals: #{Question.count} questions across #{Topic.count} topics."
