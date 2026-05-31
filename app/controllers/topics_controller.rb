class TopicsController < ApplicationController
  def generate
    subject = params[:topic_name].to_s.strip
    return render json: { error: "Enter a topic name." }, status: :unprocessable_content if subject.blank?
    return render json: { error: "Topic name must be 100 characters or fewer." }, status: :unprocessable_content if subject.length > 100

    topic = Topic.where("LOWER(name) = ?", subject.downcase).first_or_initialize(name: subject)
    topic.active = true
    topic.save!

    questions = QuestionGenerator.new(topic: topic, count: 10).generate!
    render json: { topic_id: topic.id, question_ids: questions.map(&:id), count: questions.size, topic_name: topic.name }
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_content
  rescue => e
    # QuestionGenerator::Error can't be named as a constant in rescue here because
    # Zeitwerk hasn't loaded the class yet when the rescue clause is evaluated.
    # e.class.name is safe — it reads the name of an already-instantiated object.
    raise unless e.class.name == "QuestionGenerator::Error"
    render json: { error: e.message }, status: :unprocessable_content
  end
end
