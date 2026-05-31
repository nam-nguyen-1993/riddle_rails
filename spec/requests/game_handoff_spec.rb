require "rails_helper"

RSpec.describe "game handoff", type: :request do
  it "continues to the next question without a handoff screen mid-turn" do
    user = User.create!(email: "parent@example.com", password: "password")
    topic = Topic.create!(name: "Math")
    first_question = topic.questions.create!(
      prompt: "What is 2 + 2?",
      answer_choices_attributes: [
        { body: "4", position: 1, correct: true },
        { body: "5", position: 2 }
      ]
    )
    second_question = topic.questions.create!(
      prompt: "What is 3 + 3?",
      answer_choices_attributes: [
        { body: "6", position: 1, correct: true },
        { body: "8", position: 2 }
      ]
    )
    game = user.games.create!(
      topic: topic,
      question_count: 2,
      status: "active",
      players_attributes: [
        { name: "Ava", position: 1 },
        { name: "Dad", position: 2 }
      ]
    )
    game.game_questions.create!(question: first_question, position: 1)
    game.game_questions.create!(question: second_question, position: 2)

    sign_in user, scope: :user

    post game_responses_path(game), params: {
      response: {
        answer_choice_id: first_question.correct_answer_choice.id,
        time_taken_seconds: 5
      }
    }

    expect(response).to redirect_to(game_path(game))
  end

  it "shows a confirmation screen after each player finishes their full question set" do
    user = User.create!(email: "parent@example.com", password: "password")
    topic = Topic.create!(name: "Math")
    question = topic.questions.create!(
      prompt: "What is 2 + 2?",
      answer_choices_attributes: [
        { body: "4", position: 1, correct: true },
        { body: "5", position: 2 }
      ]
    )
    game = user.games.create!(
      topic: topic,
      question_count: 1,
      status: "active",
      players_attributes: [
        { name: "Ava", position: 1 },
        { name: "Dad", position: 2 }
      ]
    )
    game.game_questions.create!(question: question, position: 1)

    sign_in user, scope: :user

    post game_responses_path(game), params: {
      response: {
        answer_choice_id: question.correct_answer_choice.id,
        time_taken_seconds: 5
      }
    }

    expect(response).to redirect_to(game_path(game, turn_complete: game.players.first.id))

    follow_redirect!

    expect(response.body).to include("Ava's Turn Is Complete")
    expect(response.body).to include("Start Dad&#39;s turn")
  end
end
