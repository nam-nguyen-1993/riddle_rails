class RecleanQuestionPrompts < ActiveRecord::Migration[8.0]
  class SeedQuestion < ActiveRecord::Base
    self.table_name = "questions"
  end

  class SeedAnswerChoice < ActiveRecord::Base
    self.table_name = "answer_choices"
  end

  class SeedGameQuestion < ActiveRecord::Base
    self.table_name = "game_questions"
  end

  class SeedResponse < ActiveRecord::Base
    self.table_name = "responses"
  end

  CONTEXT_PREFIXES = [
    "During a classroom quiz", "On the walk home from school", "While reading a picture book", "At the kitchen table",
    "During a family trivia game", "At a museum visit", "In a science notebook", "During recess trivia",
    "While making flash cards", "At the library", "During a rainy afternoon quiz", "On a weekend morning",
    "While playing school", "At homework time", "During a car ride", "At the park",
    "In a learning game", "During quiet reading time", "While asking a grown-up", "At a study table"
  ].freeze

  def up
    SeedQuestion.order(:id).find_each do |question|
      clean_prompt = clean_question_prompt(question.prompt)
      next if clean_prompt.blank?

      existing_question = SeedQuestion
        .where(topic_id: question.topic_id, prompt: clean_prompt)
        .where.not(id: question.id)
        .order(:id)
        .first

      if existing_question.present?
        remove_duplicate_or_deactivate(question, clean_prompt)
      elsif question.prompt != clean_prompt
        question.update!(prompt: clean_prompt)
      end
    end
  end

  def down
    # This intentionally keeps cleaned prompts.
  end

  private

  def remove_duplicate_or_deactivate(question, clean_prompt)
    if referenced_question?(question.id)
      question.update!(prompt: clean_prompt, active: false)
    else
      SeedAnswerChoice.where(question_id: question.id).delete_all
      question.destroy!
    end
  end

  def referenced_question?(question_id)
    SeedGameQuestion.where(question_id: question_id).exists? ||
      SeedResponse.where(question_id: question_id).exists?
  end

  def clean_question_prompt(prompt)
    clean_prompt = prompt
      .to_s
      .sub(/\AStarter bank [^:]+ \d+:\s*/, "")
      .sub(/\ASeed bank \d+:\s*/, "")
      .sub(/\A[^:]+ bank \d+:\s*/, "")
      .sub(/\A(?:#{CONTEXT_PREFIXES.map { |prefix| Regexp.escape(prefix) }.join("|")}),\s*/, "")
      .strip

    return clean_prompt if clean_prompt.blank?

    clean_prompt[0].upcase + clean_prompt[1..]
  end
end
