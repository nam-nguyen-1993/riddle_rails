require "rails_helper"

RSpec.describe QuestionGenerator do
  it "creates multiple choice questions from a strict JSON response" do
    topic = Topic.create!(name: "Science")
    chat = instance_double("RubyLLM::Chat")
    response = instance_double("RubyLLM::Message", content: {
      questions: [
        {
          prompt: "What do plants need from the sun?",
          explanation: "Plants use sunlight to help make their food.",
          choices: [
            { body: "Light", correct: true },
            { body: "Cookies", correct: false },
            { body: "Shoes", correct: false },
            { body: "Music", correct: false }
          ]
        }
      ]
    }.to_json)

    allow(RubyLLM).to receive(:chat).and_return(chat)
    allow(chat).to receive(:ask).and_return(response)

    previous_token = ENV["PREPEND_TOKEN_OPENAI"]
    ENV["PREPEND_TOKEN_OPENAI"] = "test-token"

    begin
      questions = described_class.new(topic: topic, count: 1, difficulty: "easy").generate!

      expect(questions.size).to eq(1)
      expect(questions.first.prompt).to eq("What do plants need from the sun?")
      expect(questions.first.answer_choices.size).to eq(4)
      expect(questions.first.correct_answer_choice.body).to eq("Light")
    ensure
      ENV["PREPEND_TOKEN_OPENAI"] = previous_token
    end
  end
end
