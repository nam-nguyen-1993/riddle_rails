class QuestionGenerator
  class Error < StandardError; end

  JSON_FENCE_PATTERN = /\A```(?:json)?\s*|\s*```\z/
  BOOLEAN_CASTER = ActiveModel::Type::Boolean.new

  def initialize(topic:, count:, difficulty: "easy", age_min: 7, age_max: 10)
    @topic = topic
    @count = count.to_i
    @difficulty = difficulty
    @age_min = age_min.to_i
    @age_max = age_max.to_i
  end

  def generate!
    validate_request!

    payload = parse_response(ask_model)
    questions = payload.fetch("questions")

    Question.transaction do
      questions.map { |question_payload| create_question!(question_payload) }
    end
  end

  private

  attr_reader :topic, :count, :difficulty, :age_min, :age_max

  def validate_request!
    raise Error, "Set PREPEND_TOKEN_OPENAI in your .env file before generating questions." if ENV["PREPEND_TOKEN_OPENAI"].blank?
    raise Error, "Choose between 1 and 20 questions at a time." unless count.between?(1, 20)
    raise Error, "Difficulty must be easy, medium, or hard." unless Question::DIFFICULTIES.include?(difficulty)
    raise Error, "Age minimum must be less than or equal to age maximum." if age_min > age_max
  end

  def ask_model
    RubyLLM.chat.ask(prompt).content.to_s
  end

  def prompt
    <<~PROMPT
      Act as a trivia generator. Create a set of #{count} multiple-choice questions based on the topic below.

      Topic: #{topic.name}
      Difficulty: #{difficulty}

      Rules:
      - Questions must be appropriate for children aged #{age_min}–#{age_max} years old.
      - Keep wording simple, kind, and factual.
      - Avoid copyrighted character names, brand names, and licensed content.
      - Each question must have exactly 4 answer choices with only 1 correct answer.
      - Include a short, friendly explanation of the correct answer written for a child.
      - Return only valid JSON with no markdown or code fences.

      JSON shape:
      {
        "questions": [
          {
            "prompt": "Question text",
            "explanation": "Short explanation for a child",
            "choices": [
              { "body": "Choice A", "correct": false },
              { "body": "Choice B", "correct": true },
              { "body": "Choice C", "correct": false },
              { "body": "Choice D", "correct": false }
            ]
          }
        ]
      }
    PROMPT
  end

  def parse_response(raw_response)
    JSON.parse(raw_response.to_s.strip.gsub(JSON_FENCE_PATTERN, ""))
  rescue JSON::ParserError => e
    raise Error, "The AI response was not valid JSON: #{e.message}"
  end

  def create_question!(payload)
    choices = Array(payload.fetch("choices"))
    validate_choices!(choices)

    topic.questions.create!(
      prompt: payload.fetch("prompt"),
      explanation: payload["explanation"],
      difficulty: difficulty,
      age_min: age_min,
      age_max: age_max,
      question_format: "multiple_choice",
      answer_choices_attributes: choices.each_with_index.map do |choice, index|
        {
          body: choice.fetch("body"),
          correct: BOOLEAN_CASTER.cast(choice.fetch("correct")),
          position: index + 1
        }
      end
    )
  rescue KeyError => e
    raise Error, "The AI response is missing #{e.key.inspect}."
  end

  def validate_choices!(choices)
    raise Error, "Each generated question must include exactly 4 answer choices." unless choices.size == 4

    correct_count = choices.count { |choice| BOOLEAN_CASTER.cast(choice["correct"]) }
    raise Error, "Each generated question must include exactly 1 correct answer." unless correct_count == 1
  end
end
