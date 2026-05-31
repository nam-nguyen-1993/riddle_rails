require "json"
require "set"

def clean_seed_prompt(prompt)
  prompt
    .to_s
    .sub(/\AStarter bank [^:]+ \d+:\s*/, "")
    .sub(/\ASeed bank \d+:\s*/, "")
    .sub(/\A[^:]+ bank \d+:\s*/, "")
    .strip
end

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
seed_entries = data
  .group_by { |question_data| question_data.fetch("topic") }
  .flat_map do |_topic_name, questions|
    questions.uniq { |question_data| clean_seed_prompt(question_data.fetch("prompt")) }.map do |question_data|
      question_data.merge("clean_prompt" => clean_seed_prompt(question_data.fetch("prompt")))
    end
  end
seed_prompts = seed_entries.map { |question_data| question_data["clean_prompt"] }

now = Time.current
topics_by_name = Topic.all.index_by(&:name)
seed_topic_ids = seed_entries.filter_map { |question_data| topics_by_name[question_data["topic"]]&.id }.uniq
existing_question_keys = Question
  .where(topic_id: seed_topic_ids, prompt: seed_prompts)
  .pluck(:topic_id, :prompt)
  .to_set

# 1. Bulk-insert questions. Duplicate prompt text in the JSON is deduped per
# topic so the stored prompt stays clean for players.
question_rows = seed_entries.filter_map do |q|
  topic = topics_by_name[q["topic"]]
  next unless topic
  next if existing_question_keys.include?([topic.id, q["clean_prompt"]])

  {
    topic_id:        topic.id,
    prompt:          q["clean_prompt"],
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

# 2. Fetch inserted IDs by topic and the stable clean prompt.
id_map = Question
  .where(topic_id: seed_topic_ids, prompt: seed_prompts)
  .pluck(:topic_id, :prompt, :id)
  .to_h { |topic_id, prompt, question_id| [[topic_id, prompt], question_id] }
existing_choice_pairs = AnswerChoice
  .where(question_id: id_map.values)
  .pluck(:question_id, :position)
  .to_set

# 3. Bulk-insert missing answer choices. This can repair a partial seed where
# questions were inserted but choices failed on a previous deploy.
choice_rows = seed_entries.flat_map do |q|
  topic = topics_by_name[q["topic"]]
  next [] unless topic

  qid = id_map[[topic.id, q["clean_prompt"]]]
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
