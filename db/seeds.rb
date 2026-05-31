demo_user = User.find_or_initialize_by(email: "parent@example.com")
demo_user.password = "password" if demo_user.encrypted_password.blank?
demo_user.password_confirmation = "password" if demo_user.encrypted_password.blank?
demo_user.save!

topics = [
  ["Math", "Numbers, shapes, and patterns"],
  ["Nature", "Plants, seasons, weather, and the outdoors"],
  ["History", "People and events from the past"],
  ["Science", "Everyday science for curious kids"],
  ["Riddles", "Wordplay and thinking puzzles"],
  ["Geography", "Places, maps, and the world"],
  ["Animals", "Creatures big and small"],
  ["Trading Card Trivia", "General creature-card ideas without brand names"]
]

topics.each.with_index(1) do |(name, description), position|
  topic = Topic.find_or_initialize_by(name: name)
  topic.description = description
  topic.position = position
  topic.active = true
  topic.save!
end

questions = [
  ["Math", "What is 7 + 5?", ["10", "11", "12", "13"], "12", "easy", 7, 9],
  ["Math", "Which number is even?", ["9", "11", "14", "17"], "14", "easy", 7, 9],
  ["Math", "What shape has three sides?", ["Square", "Triangle", "Circle", "Rectangle"], "Triangle", "easy", 7, 9],
  ["Math", "What is 6 x 3?", ["12", "15", "18", "21"], "18", "medium", 8, 10],
  ["Math", "What is half of 20?", ["5", "8", "10", "12"], "10", "easy", 7, 9],
  ["Math", "Which is the largest number?", ["42", "24", "34", "40"], "42", "easy", 7, 9],
  ["Math", "How many minutes are in one hour?", ["30", "45", "60", "90"], "60", "easy", 7, 10],
  ["Nature", "What do plants need from the sun?", ["Moonlight", "Sunlight", "Snow", "Sand"], "Sunlight", "easy", 7, 9],
  ["Nature", "What season usually comes after winter?", ["Spring", "Summer", "Fall", "Winter again"], "Spring", "easy", 7, 9],
  ["Nature", "What do bees collect from flowers?", ["Nectar", "Pebbles", "Leaves", "Rain"], "Nectar", "easy", 7, 10],
  ["Nature", "Which part of a plant usually grows underground?", ["Flower", "Leaf", "Root", "Stem tip"], "Root", "easy", 7, 9],
  ["Nature", "What is frozen rain called?", ["Fog", "Hail", "Wind", "Mist"], "Hail", "medium", 8, 10],
  ["Nature", "What do trees release that helps us breathe?", ["Oxygen", "Smoke", "Salt", "Dust"], "Oxygen", "medium", 8, 10],
  ["History", "Who was the first president of the United States?", ["George Washington", "Abraham Lincoln", "Thomas Edison", "Benjamin Franklin"], "George Washington", "easy", 7, 10],
  ["History", "What did people use before electric lights were common?", ["Candles", "Tablets", "Lasers", "Satellites"], "Candles", "easy", 7, 9],
  ["History", "The pyramids are strongly connected with which ancient place?", ["Egypt", "Canada", "Brazil", "Japan"], "Egypt", "easy", 7, 10],
  ["History", "Who helped many enslaved people escape through the Underground Railroad?", ["Harriet Tubman", "Amelia Earhart", "Marie Curie", "Rosa Parks"], "Harriet Tubman", "medium", 8, 10],
  ["History", "What is a museum mostly used for?", ["Saving and showing important things", "Growing tomatoes", "Landing airplanes", "Making clouds"], "Saving and showing important things", "easy", 7, 10],
  ["History", "What do we call a person who studies the past?", ["Historian", "Chef", "Pilot", "Dentist"], "Historian", "easy", 7, 10],
  ["Science", "What planet do we live on?", ["Mars", "Earth", "Venus", "Jupiter"], "Earth", "easy", 7, 9],
  ["Science", "What force pulls things toward the ground?", ["Gravity", "Music", "Color", "Heat"], "Gravity", "easy", 7, 10],
  ["Science", "What do we call water as a gas?", ["Ice", "Steam", "Stone", "Soil"], "Steam", "easy", 7, 10],
  ["Science", "Which sense uses your ears?", ["Sight", "Touch", "Hearing", "Taste"], "Hearing", "easy", 7, 9],
  ["Science", "What part of your body pumps blood?", ["Heart", "Lung", "Elbow", "Knee"], "Heart", "easy", 7, 10],
  ["Science", "Which material is attracted to a magnet?", ["Iron", "Wood", "Paper", "Plastic"], "Iron", "medium", 8, 10],
  ["Science", "What is the center of our solar system?", ["The Moon", "The Sun", "Earth", "A comet"], "The Sun", "easy", 7, 10],
  ["Riddles", "What has hands but cannot clap?", ["A clock", "A shoe", "A river", "A pencil"], "A clock", "easy", 7, 10],
  ["Riddles", "What gets wetter the more it dries?", ["A towel", "A spoon", "A chair", "A book"], "A towel", "medium", 8, 10],
  ["Riddles", "What has many keys but cannot open a door?", ["A piano", "A backpack", "A cloud", "A sandwich"], "A piano", "medium", 8, 10],
  ["Riddles", "What can you catch but not throw?", ["A cold", "A ball", "A kite", "A fish tank"], "A cold", "medium", 8, 10],
  ["Riddles", "What has a neck but no head?", ["A bottle", "A dog", "A tree", "A sock"], "A bottle", "easy", 7, 10],
  ["Riddles", "What belongs to you but other people use it more?", ["Your name", "Your lunch", "Your shoes", "Your toothbrush"], "Your name", "medium", 8, 10],
  ["Geography", "What is the name for a drawing of places on Earth?", ["Map", "Recipe", "Ticket", "Ruler"], "Map", "easy", 7, 9],
  ["Geography", "Which is the largest ocean?", ["Pacific Ocean", "Arctic Ocean", "Indian Ocean", "Atlantic Ocean"], "Pacific Ocean", "medium", 8, 10],
  ["Geography", "What country is known for the Eiffel Tower?", ["France", "Mexico", "India", "Australia"], "France", "easy", 7, 10],
  ["Geography", "What do we call a very large area of land?", ["Continent", "Puddle", "Island toy", "Street"], "Continent", "easy", 7, 10],
  ["Geography", "Which direction is usually at the top of a map?", ["North", "South", "East", "West"], "North", "easy", 7, 10],
  ["Geography", "What is the capital city of the United States?", ["Washington, D.C.", "New York City", "Chicago", "Los Angeles"], "Washington, D.C.", "medium", 8, 10],
  ["Animals", "Which animal is known for black and white stripes?", ["Zebra", "Lion", "Frog", "Rabbit"], "Zebra", "easy", 7, 9],
  ["Animals", "What do caterpillars turn into?", ["Butterflies or moths", "Sharks", "Trees", "Rocks"], "Butterflies or moths", "easy", 7, 10],
  ["Animals", "Which animal is a mammal?", ["Dolphin", "Goldfish", "Lizard", "Frog"], "Dolphin", "medium", 8, 10],
  ["Animals", "What is a baby frog called?", ["Tadpole", "Cub", "Calf", "Chick"], "Tadpole", "easy", 7, 10],
  ["Animals", "Which bird cannot fly but can swim very well?", ["Penguin", "Eagle", "Sparrow", "Parrot"], "Penguin", "easy", 7, 10],
  ["Animals", "What do herbivores mostly eat?", ["Plants", "Rocks", "Metal", "Glass"], "Plants", "easy", 7, 10],
  ["Trading Card Trivia", "In many card games, what does a shield usually mean?", ["Protection", "Speed", "Lunch", "Music"], "Protection", "easy", 7, 10],
  ["Trading Card Trivia", "If a creature is weak to water, which card might be strong against it?", ["Water", "Fire", "Paper", "Sound"], "Water", "easy", 7, 10],
  ["Trading Card Trivia", "What does it mean to trade fairly?", ["Both people agree and understand", "One person hides a card", "No one talks", "Only the fastest wins"], "Both people agree and understand", "easy", 7, 10],
  ["Trading Card Trivia", "Which number is usually better for a card's health?", ["A higher number", "A lower number", "No number", "A backwards number"], "A higher number", "easy", 7, 10],
  ["Trading Card Trivia", "What should you do with a borrowed card?", ["Take care of it", "Bend it", "Lose it", "Color on it"], "Take care of it", "easy", 7, 10],
  ["Trading Card Trivia", "What kind of card usually helps another card?", ["Support card", "Snack card", "Window card", "Pillow card"], "Support card", "easy", 7, 10]
]

questions.each do |topic_name, prompt, choices, correct_answer, difficulty, age_min, age_max|
  topic = Topic.find_by!(name: topic_name)
  question = topic.questions.find_or_initialize_by(prompt: prompt)
  question.difficulty = difficulty
  question.age_min = age_min
  question.age_max = age_max
  question.question_format = "multiple_choice"
  question.active = true
  question.save!(validate: false) if question.new_record?

  choices.each.with_index(1) do |body, position|
    answer_choice = question.answer_choices.find_or_initialize_by(position: position)
    answer_choice.body = body
    answer_choice.correct = body == correct_answer
    answer_choice.save!
  end

  question.reload.save!
end

def save_multiple_choice_question!(topic_name:, prompt:, choices:, correct_answer:, difficulty:, age_min:, age_max:)
  topic = Topic.find_by!(name: topic_name)
  question = topic.questions.find_or_initialize_by(prompt: prompt)
  question.difficulty = difficulty
  question.age_min = age_min
  question.age_max = age_max
  question.question_format = "multiple_choice"
  question.active = true
  question.save!(validate: false) if question.new_record?

  choices.each.with_index(1) do |body, position|
    answer_choice = question.answer_choices.find_or_initialize_by(position: position)
    answer_choice.body = body
    answer_choice.correct = body == correct_answer
    answer_choice.save!
  end

  question.reload.save!
end

def difficulty_for(index)
  case index % 5
  when 0
    "medium"
  when 1
    "easy"
  when 2
    "easy"
  when 3
    "medium"
  else
    "hard"
  end
end

def age_range_for(index)
  min = 7 + (index % 3)
  [min, [min + 1, 10].min]
end

def rotated_choices(correct, wrong_choices, index)
  fallback_choices = ["All of these", "None of these", "Not sure", "It depends", "Ask a teacher"]
  choices = ([correct] + wrong_choices + fallback_choices).uniq.first(4)
  choices.rotate(index % choices.length)
end

250.times do |index|
  number = index + 1
  age_min, age_max = age_range_for(index)
  difficulty = difficulty_for(index)

  case index % 5
  when 0
    a = 3 + (index % 17)
    b = 2 + (index % 13)
    correct = (a + b).to_s
    wrong = [(a + b - 1).to_s, (a + b + 1).to_s, (a + b + 3).to_s]
    prompt = "Math builder #{number}: What is #{a} + #{b}?"
  when 1
    a = 8 + (index % 20)
    b = 1 + (index % 7)
    correct = (a - b).to_s
    wrong = [(a - b - 2).to_s, (a - b + 2).to_s, (a + b).to_s]
    prompt = "Math builder #{number}: What is #{a} - #{b}?"
  when 2
    a = 2 + (index % 9)
    b = 2 + (index % 8)
    correct = (a * b).to_s
    wrong = [(a * b + a).to_s, (a * b - b).to_s, (a + b).to_s]
    prompt = "Math builder #{number}: What is #{a} x #{b}?"
  when 3
    shapes = [["triangle", "3"], ["square", "4"], ["pentagon", "5"], ["hexagon", "6"], ["octagon", "8"]]
    shape, sides = shapes[index % shapes.length]
    correct = sides
    wrong = (["2", "3", "4", "5", "6", "7", "8"] - [correct]).sample(3, random: Random.new(index))
    prompt = "Math builder #{number}: How many sides does a #{shape} have?"
  else
    total = 10 + ((index % 20) * 2)
    correct = (total / 2).to_s
    wrong = [(total / 2 - 1).to_s, (total / 2 + 2).to_s, (total - 2).to_s]
    prompt = "Math builder #{number}: What is half of #{total}?"
  end

  save_multiple_choice_question!(
    topic_name: "Math",
    prompt: prompt,
    choices: rotated_choices(correct, wrong, index),
    correct_answer: correct,
    difficulty: difficulty,
    age_min: age_min,
    age_max: age_max
  )
end

topic_facts = {
  "Nature" => [
    ["What do flowers often use to make seeds?", "Pollen", ["Pebbles", "Smoke", "Plastic"]],
    ["Which part of a tree carries water from roots to leaves?", "Trunk", ["Cloud", "Feather", "Shell"]],
    ["What do leaves help plants make?", "Food", ["Shoes", "Glass", "Music"]],
    ["Which weather has tiny drops floating near the ground?", "Fog", ["Thunder", "Sunburn", "Pebbles"]],
    ["What do many plants grow from?", "Seeds", ["Coins", "Buttons", "Wires"]],
    ["Which natural place has many trees close together?", "Forest", ["Desert", "Kitchen", "Bridge"]],
    ["What do roots usually take in from soil?", "Water", ["Moonlight", "Paint", "Wind"]],
    ["What do clouds often bring?", "Rain", ["Sandwiches", "Books", "Shoes"]],
    ["Which season often has colorful falling leaves?", "Fall", ["Spring", "Summer", "Winter"]],
    ["What do butterflies drink from flowers?", "Nectar", ["Salt", "Clay", "Ink"]]
  ],
  "History" => [
    ["What do historians study?", "The past", ["Outer space only", "Future weather", "Video games only"]],
    ["What is an artifact?", "An object from the past", ["A type of cloud", "A math symbol", "A snack"]],
    ["What did many people use before cars?", "Horses and wagons", ["Rocket boots", "Submarines", "Drones"]],
    ["What does a timeline show?", "Events in order", ["Only colors", "Animal sounds", "Secret codes"]],
    ["Who writes about events they lived through?", "Witnesses", ["Robots", "Mountains", "Pencils"]],
    ["What is a primary source?", "A record from the time", ["A made-up story", "A lunch menu", "A weather app"]],
    ["Why do we save old letters and photos?", "To learn about the past", ["To make soup", "To grow plants", "To charge batteries"]],
    ["What is a monument?", "A structure that remembers something important", ["A type of shoe", "A small bug", "A kitchen tool"]],
    ["What is a biography?", "A story of a person's life", ["A map of oceans", "A list of jokes", "A plant chart"]],
    ["What does century mean?", "100 years", ["10 years", "1 year", "1,000 days"]]
  ],
  "Science" => [
    ["What tool helps you see tiny things?", "Microscope", ["Telescope", "Ruler", "Compass"]],
    ["What is water as a solid called?", "Ice", ["Steam", "Smoke", "Dust"]],
    ["What do lungs help you do?", "Breathe", ["Hear", "Taste", "Blink"]],
    ["What does a thermometer measure?", "Temperature", ["Height", "Sound", "Weight only"]],
    ["What happens when ice gets warm enough?", "It melts", ["It sings", "It turns to wood", "It becomes metal"]],
    ["Which state of matter keeps its own shape?", "Solid", ["Liquid", "Gas", "Mist"]],
    ["What do magnets pull on strongly?", "Iron", ["Paper", "Cotton", "Bread"]],
    ["What do scientists test?", "Ideas", ["Only jokes", "Only shoes", "Only songs"]],
    ["What gives Earth daytime light?", "The Sun", ["The ocean", "A mountain", "The wind"]],
    ["What carries messages from your brain?", "Nerves", ["Teeth", "Hair", "Fingernails"]]
  ],
  "Riddles" => [
    ["What has teeth but cannot bite?", "A comb", ["A pillow", "A cloud", "A sock"]],
    ["What runs but has no legs?", "Water", ["A chair", "A pencil", "A hat"]],
    ["What has words but never speaks?", "A book", ["A spoon", "A leaf", "A shoe"]],
    ["What has one eye but cannot see?", "A needle", ["A clock", "A blanket", "A cup"]],
    ["What can fill a room but takes no space?", "Light", ["A rock", "A desk", "A backpack"]],
    ["What has a face and two hands but no arms?", "A clock", ["A river", "A shoe", "A bowl"]],
    ["What goes up but never comes down?", "Your age", ["A ball", "A kite", "A ladder"]],
    ["What has cities but no houses?", "A map", ["A garden", "A sandwich", "A bicycle"]],
    ["What has a tail and a head but no body?", "A coin", ["A bird", "A carrot", "A pencil"]],
    ["What can you break without touching?", "A promise", ["A window", "A plate", "A stick"]]
  ],
  "Geography" => [
    ["What do we call water surrounded by land?", "Lake", ["Mountain", "Island", "Valley"]],
    ["What do we call land surrounded by water?", "Island", ["River", "Canyon", "Desert"]],
    ["What line divides Earth into northern and southern halves?", "Equator", ["Border", "Trail", "Sidewalk"]],
    ["Which tool shows direction?", "Compass", ["Thermometer", "Scale", "Spoon"]],
    ["What is a desert known for having very little of?", "Rain", ["Sand sometimes", "Sunlight", "Wind"]],
    ["What is a mountain?", "A very high landform", ["A kind of river", "A city street", "A tiny lake"]],
    ["What do we call a stream of flowing water?", "River", ["Island", "Plateau", "Glacier only"]],
    ["What is a capital city?", "A government's main city", ["The smallest village", "A farm tool", "A type of cloud"]],
    ["What do map symbols explain?", "Places or features", ["Only animal names", "Only foods", "Only songs"]],
    ["What ocean is east of the United States?", "Atlantic Ocean", ["Pacific Ocean", "Indian Ocean", "Arctic Ocean"]]
  ],
  "Animals" => [
    ["What do carnivores mostly eat?", "Other animals", ["Only rocks", "Only sunlight", "Only water"]],
    ["What helps fish breathe underwater?", "Gills", ["Fur", "Feathers", "Claws"]],
    ["What body covering do birds have?", "Feathers", ["Scales", "Shells", "Leaves"]],
    ["Which animal group feeds milk to babies?", "Mammals", ["Insects", "Fish", "Reptiles only"]],
    ["What do nocturnal animals do?", "Stay active at night", ["Sleep all year", "Never eat", "Live only in water"]],
    ["What is camouflage used for?", "Blending in", ["Flying faster", "Making music", "Growing taller"]],
    ["What do many reptiles have on their skin?", "Scales", ["Feathers", "Wool", "Leaves"]],
    ["What is an animal's home called?", "Habitat", ["Recipe", "Compass", "Helmet"]],
    ["What do bees make?", "Honey", ["Milk", "Cotton", "Glass"]],
    ["What do we call animals with backbones?", "Vertebrates", ["Planets", "Minerals", "Mushrooms"]]
  ],
  "Trading Card Trivia" => [
    ["What should you check before trading a card?", "That both people agree", ["Who can yell loudest", "The weather", "The card's smell"]],
    ["What protects cards from bends and scratches?", "A sleeve", ["A spoon", "A sock with holes", "A wet towel"]],
    ["What does a card's attack number usually show?", "How strong the move is", ["How old the card is", "How shiny the table is", "How loud it sounds"]],
    ["What does a card's health number usually show?", "How much damage it can take", ["How tasty it is", "How many pages it has", "How fast it reads"]],
    ["What is a good habit with borrowed cards?", "Return them carefully", ["Fold them", "Hide them", "Write on them"]],
    ["What does a support card usually do?", "Helps your play", ["Turns into lunch", "Makes rain", "Erases the rules"]],
    ["Why sort cards by type?", "To find them faster", ["To make them heavier", "To change their color", "To make them noisy"]],
    ["What should you do if a trade feels unfair?", "Pause and ask an adult", ["Rush faster", "Hide the card", "Pretend not to know"]],
    ["What is a collection?", "A group of cards you keep", ["A single pencil", "A kind of cloud", "A recipe"]],
    ["What does taking turns mean?", "Players act one at a time", ["Everyone shouts together", "No one plays", "Cards are hidden forever"]]
  ]
}

topic_facts.each do |topic_name, facts|
  250.times do |index|
    fact_prompt, correct, wrong = facts[index % facts.length]
    age_min, age_max = age_range_for(index)
    save_multiple_choice_question!(
      topic_name: topic_name,
      prompt: "#{topic_name} bank #{index + 1}: #{fact_prompt}",
      choices: rotated_choices(correct, wrong, index),
      correct_answer: correct,
      difficulty: difficulty_for(index),
      age_min: age_min,
      age_max: age_max
    )
  end
end

# ── LLM-generated question bank (bulk insert — fast) ───────────────────────
questions_file = Rails.root.join("db/seeds/questions.json")
if File.exist?(questions_file)
  require "json"
  data = JSON.parse(File.read(questions_file))
  now  = Time.current

  # Build topic lookup (create any missing ones)
  topic_names = data.map { |q| q["topic"] }.uniq
  topic_names.each { |name| Topic.find_or_create_by!(name: name) { |t| t.active = true } }
  topics_by_name = Topic.where(name: topic_names).index_by(&:name)

  # Skip prompts already in the database
  existing = Question.where(prompt: data.map { |q| q["prompt"] }).pluck(:prompt).to_set
  new_data  = data.reject { |q| existing.include?(q["prompt"]) }

  if new_data.empty?
    puts "LLM questions: all #{data.size} already exist, nothing to add."
  else
    # Bulk-insert questions (no callbacks — much faster than create!)
    question_rows = new_data.filter_map do |q|
      topic = topics_by_name[q["topic"]]
      next unless topic
      { topic_id: topic.id, prompt: q["prompt"], explanation: q["explanation"],
        difficulty: q["difficulty"] || "easy", age_min: q["age_min"] || 7,
        age_max: q["age_max"] || 10, question_format: "multiple_choice",
        active: true, created_at: now, updated_at: now }
    end

    Question.insert_all(question_rows)

    # Fetch the just-inserted IDs
    inserted = Question.where(prompt: new_data.map { |q| q["prompt"] }).pluck(:prompt, :id).to_h

    # Bulk-insert answer choices
    choice_rows = new_data.flat_map do |q|
      qid = inserted[q["prompt"]]
      next [] unless qid
      q["choices"].map do |c|
        { question_id: qid, body: c["body"], correct: c["correct"],
          position: c["position"], created_at: now, updated_at: now }
      end
    end

    choice_rows.each_slice(1000) { |batch| AnswerChoice.insert_all(batch) }

    puts "LLM questions: #{question_rows.size} added in bulk (#{data.size - new_data.size} already existed)."
  end
end
