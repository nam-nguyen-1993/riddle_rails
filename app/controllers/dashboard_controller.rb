class DashboardController < ApplicationController
  def show
    @recent_games = current_user.games.recent.includes(:topic, :players, :game_questions).limit(12)
    @recent_games_by_day = @recent_games.group_by { |game| game.created_at.to_date }
    @topics = Topic.active.ordered
    @question_bank_stats = question_bank_stats
  end

  private

  def question_bank_stats
    played_counts = Response
      .joins(:game, question: :topic)
      .where(games: { user_id: current_user.id })
      .distinct
      .group("topics.id")
      .count("questions.id")

    total_counts = Question.active.group(:topic_id).count

    @topics.map do |topic|
      total = total_counts[topic.id] || 0
      played = played_counts[topic.id] || 0
      percentage = total.positive? ? ((played.to_f / total) * 100).round : 0

      { topic: topic, total: total, played: played, percentage: percentage }
    end
  end
end
