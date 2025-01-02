# lib/gem_sorter.rb

load File.expand_path('tasks/gem_sorter.rake', __dir__) if defined?(Rake)

module GemSorter
  class Sorter
    def initialize(filepath)
      @filepath = filepath
      @content = File.read(filepath)
    end

    def sort
      parts = @content.split(/^group/)
      main_section = parts.shift
      group_sections = parts

      source_line, gems = process_main_section(main_section)

      sorted_gems = sort_gem_blocks(gems)

      result = []
      result << source_line
      result << ''
      result.concat(sorted_gems)
      result << ''

      group_sections.each do |section|
        group_gems = process_group_section(section)
        result << "group#{section.split("\n").first}"
        result.concat(sort_gem_blocks(group_gems).map { |line| "  #{line}" })
        result << 'end'
        result << ''
      end

      result.join("\n")
    end

    private

    def process_main_section(section)
      lines = section.split("\n").map(&:strip).reject(&:empty?)
      source_line = lines.shift

      gems = []
      current_comments = []

      lines.each do |line|
        if line.start_with?('#')
          current_comments << line
        elsif line.start_with?('gem')
          gems << {
            comments: current_comments,
            gem_line: line
          }
          current_comments = []
        end
      end

      [source_line, gems]
    end

    def process_group_section(section)
      lines = section.split("\n").map(&:strip).reject(&:empty?)
      lines = lines[1...-1]

      gems = []
      current_comments = []

      lines.each do |line|
        if line.start_with?('#')
          current_comments << line
        elsif line.start_with?('gem')
          gems << {
            comments: current_comments,
            gem_line: line
          }
          current_comments = []
        end
      end

      gems
    end

    def sort_gem_blocks(gems)
      sorted = gems.sort_by do |gem_block|
        gem_block[:gem_line].match(/gem\s*"([^"]+)"/)[1].downcase
      end

      result = []
      sorted.each do |gem_block|
        result.concat(gem_block[:comments]) unless gem_block[:comments].empty?
        result << gem_block[:gem_line]
      end

      result
    end
  end
end
