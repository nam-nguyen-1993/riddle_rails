require "rails_helper"

RSpec.describe "riddle game data model", type: :model do
  it "creates a playable multiple choice game with ordered players and choices" do
    user = User.create!(email: "parent@example.com", password: "password")
    topic = Topic.create!(name: "Math", position: 1)
    question = topic.questions.create!(
      prompt: "What is 2 + 2?",
      answer_choices_attributes: [
        { body: "3", position: 1 },
        { body: "4", position: 2, correct: true },
        { body: "5", position: 3 }
      ]
    )
    game = user.games.create!(
      topic: topic,
      question_count: 1,
      players_attributes: [
        { name: "Dad", position: 2 },
        { name: "Ava", position: 1 }
      ]
    )

    game.game_questions.create!(question: question, position: 1)
    response = Response.create!(
      game: game,
      player: game.players.first,
      question: question,
      answer_choice: question.correct_answer_choice,
      time_taken_seconds: 8
    )

    expect(topic.active_questions).to contain_exactly(question)
    expect(question.answer_choices.map(&:body)).to eq(["3", "4", "5"])
    expect(game.players.reload.map(&:name)).to eq(["Ava", "Dad"])
    expect(response).to be_correct
    expect(user.played_questions).to contain_exactly(question)
  end

  it "keeps responses scoped to the selected game" do
    user = User.create!(email: "parent@example.com", password: "password")
    topic = Topic.create!(name: "Science")
    question = topic.questions.create!(
      prompt: "Which planet do we live on?",
      answer_choices_attributes: [
        { body: "Earth", position: 1, correct: true },
        { body: "Mars", position: 2 }
      ]
    )
    game = user.games.create!(topic: topic, players_attributes: [{ name: "Ava", position: 1 }])
    other_game = user.games.create!(topic: topic, players_attributes: [{ name: "Dad", position: 1 }])
    other_game.game_questions.create!(question: question, position: 1)

    response = Response.new(
      game: game,
      player: game.players.first,
      question: question,
      answer_choice: question.correct_answer_choice
    )

    expect(response).not_to be_valid
    expect(response.errors[:question]).to include("must be part of the game")
  end

  it "lets each player answer the full question set before the next player starts" do
    user = User.create!(email: "parent@example.com", password: "password")
    topic = Topic.create!(name: "Riddles")
    first_question = topic.questions.create!(
      prompt: "What has hands but cannot clap?",
      answer_choices_attributes: [
        { body: "A clock", position: 1, correct: true },
        { body: "A table", position: 2 }
      ]
    )
    second_question = topic.questions.create!(
      prompt: "What has many keys but cannot open a door?",
      answer_choices_attributes: [
        { body: "A piano", position: 1, correct: true },
        { body: "A cloud", position: 2 }
      ]
    )
    game = user.games.create!(
      topic: topic,
      question_count: 2,
      players_attributes: [
        { name: "Ava", position: 1 },
        { name: "Dad", position: 2 }
      ]
    )
    game.game_questions.create!(question: first_question, position: 1)
    game.game_questions.create!(question: second_question, position: 2)

    expect(game.current_player.name).to eq("Ava")
    expect(game.current_question).to eq(first_question)

    Response.create!(game: game, player: game.current_player, question: game.current_question, answer_choice: first_question.correct_answer_choice)
    expect(game.current_player.name).to eq("Ava")
    expect(game.current_question).to eq(second_question)

    Response.create!(game: game, player: game.current_player, question: game.current_question, answer_choice: second_question.correct_answer_choice)
    expect(game.current_player.name).to eq("Dad")
    expect(game.current_question).to eq(first_question)

    Response.create!(game: game, player: game.current_player, question: game.current_question)
    expect(game.current_player.name).to eq("Dad")
    expect(game.current_question).to eq(second_question)

    Response.create!(game: game, player: game.current_player, question: game.current_question)
    expect(game).to be_complete_round
  end

  it "can select mixed questions across topics" do
    user = User.create!(email: "parent@example.com", password: "password")
    math = Topic.create!(name: "Math")
    science = Topic.create!(name: "Science")
    math_question = math.questions.create!(
      prompt: "What is 1 + 1?",
      answer_choices_attributes: [
        { body: "2", position: 1, correct: true },
        { body: "3", position: 2 }
      ]
    )
    science_question = science.questions.create!(
      prompt: "What planet do we live on?",
      answer_choices_attributes: [
        { body: "Earth", position: 1, correct: true },
        { body: "Mars", position: 2 }
      ]
    )
    game = user.games.create!(
      topic: math,
      mixed_questions: true,
      question_count: 2,
      players_attributes: [{ name: "Ava", position: 1 }]
    )

    game.select_questions!

    expect(game.questions).to contain_exactly(math_question, science_question)
  end

  it "prefers questions that were not played recently" do
    user = User.create!(email: "parent@example.com", password: "password")
    topic = Topic.create!(name: "Math")
    older_question = topic.questions.create!(
      prompt: "Older played question",
      answer_choices_attributes: [
        { body: "Correct", position: 1, correct: true },
        { body: "Wrong", position: 2 }
      ]
    )
    recent_question = topic.questions.create!(
      prompt: "Recently played question",
      answer_choices_attributes: [
        { body: "Correct", position: 1, correct: true },
        { body: "Wrong", position: 2 }
      ]
    )
    old_game = user.games.create!(topic: topic, players_attributes: [{ name: "Ava", position: 1 }])
    old_game.game_questions.create!(question: older_question, position: 1)
    recent_game = user.games.create!(topic: topic, players_attributes: [{ name: "Ava", position: 1 }])
    recent_game.game_questions.create!(question: recent_question, position: 1)
    Response.create!(game: old_game, player: old_game.players.first, question: older_question, answer_choice: older_question.correct_answer_choice, answered_at: 2.months.ago)
    Response.create!(game: recent_game, player: recent_game.players.first, question: recent_question, answer_choice: recent_question.correct_answer_choice, answered_at: 1.day.ago)
    game = user.games.create!(topic: topic, question_count: 1, players_attributes: [{ name: "Ava", position: 1 }])

    game.select_questions!

    expect(game.questions).to contain_exactly(older_question)
  end

  it "identifies a clear winner and ties among top scorers" do
    user = User.create!(email: "parent@example.com", password: "password")
    topic = Topic.create!(name: "Math")
    winning_game = user.games.create!(
      topic: topic,
      players_attributes: [
        { name: "Ava", position: 1, score: 3 },
        { name: "Dad", position: 2, score: 1 },
        { name: "Sam", position: 3, score: 2 }
      ]
    )
    tied_game = user.games.create!(
      topic: topic,
      players_attributes: [
        { name: "Ava", position: 1, score: 3 },
        { name: "Dad", position: 2, score: 3 },
        { name: "Sam", position: 3, score: 2 }
      ]
    )

    expect(winning_game).not_to be_tied
    expect(winning_game.winner.name).to eq("Ava")
    expect(tied_game).to be_tied
    expect(tied_game.winner).to be_nil
    expect(tied_game.top_players.map(&:name)).to eq(["Ava", "Dad"])

    winning_game.complete!
    tied_game.complete!

    expect(winning_game.result_summary).to eq("Ava won")
    expect(tied_game.result_summary).to eq("Tie: Ava and Dad")
  end
end
