require "rails_helper"

RSpec.describe "game setup", type: :request do
  it "starts a mixed question game" do
    user = User.create!(email: "parent@example.com", password: "password")
    math = Topic.create!(name: "Math")
    science = Topic.create!(name: "Science")
    create_question(math, "What is 2 + 2?")
    create_question(science, "What planet do we live on?")

    sign_in user, scope: :user

    post games_path, params: game_params(question_source: "mixed")

    game = user.games.last
    expect(response).to redirect_to(game_path(game))
    expect(game).to be_mixed_questions
    expect(game.questions.size).to eq(2)
  end

  it "does not crash when the question bank has not been seeded" do
    user = User.create!(email: "parent@example.com", password: "password")

    sign_in user, scope: :user

    expect do
      post games_path, params: game_params(question_source: "mixed")
    end.not_to change(Game, :count)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("The question bank is empty. Please seed topics before starting a game.")
  end

  it "starts a game from a specific saved topic" do
    user = User.create!(email: "parent@example.com", password: "password")
    math = Topic.create!(name: "Math")
    science = Topic.create!(name: "Science")
    create_question(math, "What is 2 + 2?")
    science_question = create_question(science, "What planet do we live on?")

    sign_in user, scope: :user

    post games_path, params: game_params(question_source: "specific", topic_id: science.id)

    game = user.games.last
    expect(response).to redirect_to(game_path(game))
    expect(game).not_to be_mixed_questions
    expect(game.topic).to eq(science)
    expect(game.questions).to contain_exactly(science_question)
  end

  it "creates a custom topic and generates questions for it" do
    user = User.create!(email: "parent@example.com", password: "password")
    Topic.create!(name: "Math")
    topic = Topic.create!(name: "Space explorers")
    old_question = create_question(topic, "Older space question?")
    generated_questions = 10.times.map { |i| create_question(topic, "Generated question #{i + 1}?") }

    sign_in user, scope: :user

    post games_path, params: game_params(
      question_source: "custom",
      pregenerated_topic_id: topic.id,
      question_ids: generated_questions.map(&:id).join(","),
      question_count: 10
    )

    game = user.games.last
    expect(response).to redirect_to(game_path(game))
    expect(game.topic).to eq(topic)
    expect(game).not_to be_mixed_questions
    expect(game.questions.count).to eq(10)
    expect(game.questions).not_to include(old_question)
  end

  it "rejects pregenerated question ids that do not belong to the generated topic" do
    user = User.create!(email: "parent@example.com", password: "password")
    generated_topic = Topic.create!(name: "Space explorers")
    other_topic = Topic.create!(name: "Animals")
    generated_questions = 5.times.map { |i| create_question(generated_topic, "Generated question #{i + 1}?") }
    other_questions = 5.times.map { |i| create_question(other_topic, "Other question #{i + 1}?") }

    sign_in user, scope: :user

    expect do
      post games_path, params: game_params(
        question_source: "custom",
        pregenerated_topic_id: generated_topic.id,
        question_ids: (generated_questions + other_questions).map(&:id).join(","),
        question_count: 10
      )
    end.not_to change(Game, :count)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Generate enough questions for this topic before starting the game.")
  end

  it "requires a pre-generated topic before starting a custom topic game" do
    user = User.create!(email: "parent@example.com", password: "password")
    Topic.create!(name: "Math")

    sign_in user, scope: :user

    expect do
      post games_path, params: game_params(question_source: "custom")
    end.not_to change(Game, :count)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Confirm your AI topic before starting the game.")
  end

  def game_params(question_source:, topic_id: nil, pregenerated_topic_id: nil, question_ids: nil, question_count: 2)
    {
      game: {
        question_source: question_source,
        topic_id: topic_id,
        pregenerated_topic_id: pregenerated_topic_id,
        question_ids: question_ids,
        question_count: question_count,
        seconds_per_turn: 40,
        player_names: [ "Ava", "Dad" ]
      }
    }
  end

  def create_question(topic, prompt)
    topic.questions.create!(
      prompt: prompt,
      answer_choices_attributes: [
        { body: "Correct", position: 1, correct: true },
        { body: "Wrong", position: 2 },
        { body: "Maybe", position: 3 },
        { body: "Not this time", position: 4 }
      ]
    )
  end
end
