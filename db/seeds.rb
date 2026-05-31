require "json"

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

# ── Question bank (bulk insert from questions.json) ─────────────────────────
questions_file = Rails.root.join("db/seeds/questions.json")

unless File.exist?(questions_file)
  puts "questions.json not found — skipping question import."
  return
end

if Question.count >= 100
  puts "Questions already seeded (#{Question.count}). Skipping."
else
  data           = JSON.parse(File.read(questions_file))
  now            = Time.current
  topics_by_name = Topic.all.index_by(&:name)

  # ── 1. Bulk-insert questions ──────────────────────────────────────────────
  question_rows = data.filter_map do |q|
    topic = topics_by_name[q["topic"]]
    next unless topic
    {
      topic_id:        topic.id,
      prompt:          q["prompt"],
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

  Question.insert_all(question_rows)

  # ── 2. Fetch inserted IDs via topic_id (10-item query, not 2500-item) ─────
  topic_ids = topics_by_name.values.map(&:id)
  id_map = Question.where(topic_id: topic_ids)
                   .pluck(:topic_id, :prompt, :id)
                   .to_h { |tid, prompt, qid| [[tid, prompt], qid] }

  # ── 3. Bulk-insert answer choices ─────────────────────────────────────────
  choice_rows = data.flat_map do |q|
    topic = topics_by_name[q["topic"]]
    next [] unless topic
    qid = id_map[[topic.id, q["prompt"]]]
    next [] unless qid
    q["choices"].map do |c|
      {
        question_id: qid,
        body:        c["body"],
        correct:     c["correct"],
        position:    c["position"],
        created_at:  now,
        updated_at:  now
      }
    end
  end

  choice_rows.each_slice(1000) { |batch| AnswerChoice.insert_all(batch) }

  puts "Seeded #{Question.count} questions across #{Topic.count} topics."
end
