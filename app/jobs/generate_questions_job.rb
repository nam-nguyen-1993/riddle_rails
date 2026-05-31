class GenerateQuestionsJob < ApplicationJob
  queue_as :default

  def perform(topic, count:, difficulty: "easy", age_min: 7, age_max: 10)
    QuestionGenerator.new(
      topic: topic,
      count: count,
      difficulty: difficulty,
      age_min: age_min,
      age_max: age_max
    ).generate!
  end
end
