namespace :questions do
  desc "Generate questions until each active topic reaches TARGET (default 500). Run on production with: bundle exec rake questions:generate TARGET=500"
  task generate: :environment do
    target   = (ENV["TARGET"] || 500).to_i
    batch    = 20
    topics   = Topic.active.ordered

    difficulties = %w[easy medium hard easy medium].freeze
    age_pairs    = [[7, 10], [8, 11], [9, 12], [7, 13], [10, 13]].freeze

    total_added = 0

    topics.each do |topic|
      current = topic.questions.active.multiple_choice.count
      needed  = [target - current, 0].max

      if needed.zero?
        puts "%-30s %d/%d ✓ (already at target)" % [topic.name, current, target]
        next
      end

      puts "\n%-30s %d → %d  (%d to add)" % [topic.name, current, target, needed]

      batches_needed = (needed.to_f / batch).ceil

      batches_needed.times do |i|
        count      = [batch, needed - i * batch].min
        difficulty = difficulties[i % difficulties.size]
        age_min, age_max = age_pairs[i % age_pairs.size]

        print "  [%02d/%02d] %-6s age %2d–%2d  count %-2d ... " % [i + 1, batches_needed, difficulty, age_min, age_max, count]
        $stdout.flush

        begin
          QuestionGenerator.new(
            topic:      topic,
            count:      count,
            difficulty: difficulty,
            age_min:    age_min,
            age_max:    age_max
          ).generate!
          total_added += count
          puts "✓  (total added: #{total_added})"
        rescue => e
          puts "✗  #{e.message}"
          sleep 2
        end

        sleep 0.3
      end
    end

    puts "\n#{"=" * 50}"
    puts "Done. Added #{total_added} questions."
    puts "Grand total in bank: #{Question.active.count}"
  end
end
