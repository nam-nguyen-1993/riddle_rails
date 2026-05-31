class QuestionsController < ApplicationController
  before_action :set_topic

  def index
    @questions = @topic.questions.active.includes(:answer_choices).order(:prompt)
  end

  def destroy
    @topic.questions.find(params[:id]).update!(active: false)
    redirect_to topic_questions_path(@topic)
  end

  private

  def set_topic
    @topic = Topic.find(params[:topic_id])
  end
end
