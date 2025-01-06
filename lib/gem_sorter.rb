# lib/gem_sorter.rb
require 'net/http'
require 'cgi'

load File.expand_path('tasks/gem_sorter.rake', __dir__) if defined?(Rake)

module GemSorter
  class Sorter
    def initialize(task_config)
      @config = task_config
      @filepath = task_config.gemfile_path
      @content = File.read(task_config.gemfile_path)
      @versions = nil
    end

    def sort
      parts = @content.split(/^group/)
      main_section = parts.shift
      group_sections = parts

      source_line, gems = process_main_section(main_section)

      update_gem_summaries(gems) if @config.update_comments
      update_version_text(gems) if @config.update_versions

      sorted_gems = sort_gem_blocks(gems)

      result = []
      result << source_line
      result << ''
      result.concat(sorted_gems)
      result << ''

      group_sections.each do |section|
        group_gems = process_group_section(section)
        update_gem_summaries(group_gems) if @config.update_comments
        update_version_text(group_gems) if @config.update_versions
        result << "group#{section.split("\n").first}"
        result.concat(sort_gem_blocks(group_gems).map { |line| "  #{line}" })
        result << 'end'
        result << ''
      end

      result.join("\n")
    end

    private

    def update_version_text(gems)
      @versions ||= fetch_versions_from_lockfile("#{@filepath}.lock")
      gems.each do |gem_block|
        gem_name = gem_block[:gem_line].match(/gem\s*"([^"]+)"/)[1]
        next if @config.ignore_gems.include?(gem_name) || @config.ignore_gem_versions.include?(gem_name)

        version = @versions[gem_name]
        extra_params = extract_params(gem_block[:gem_line])
        base = version ? "#{fetch_gemfile_text(gem_name, version, gem_block[:gem_line])}" : gem_block[:gem_line]
        return base if base == gem_block[:gem_line]

        gem_block[:gem_line] = [base, extra_params].select { |value| !value.nil? && !value.empty? }.join(',')
      end
    end

    def extract_params(gem_line)
      return nil unless gem_line =~ /gem\s*"([^"]+)"/

      if gem_line =~ /gem\s*"[^"]*"\s*,\s*(.*)/
        additional_params = $1.strip
        return nil if additional_params.empty?
        params_with_colon = additional_params.scan(/(\w+:\s*[^,]+)/).flatten
        return params_with_colon.join(', ') unless params_with_colon.empty?
      end
      nil
    end

    def update_gem_summaries(gems)
      gems.each do |gem_block|
        gem_name = gem_block[:gem_line].match(/gem\s*"([^"]+)"/)[1]
        next if @config.ignore_gems.include?(gem_name) || @config.ignore_gem_comments.include?(gem_name)

        if summary = get_summary(gem_name, false)
          gem_block[:comments] = ["# #{summary}"]
        end
      end
    end

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
        match_data = gem_block[:gem_line].match(/gem\s*['"]([^'"]+)['"]/)
        if match_data
          match_data[1].downcase
        else
          ''
        end
      end

      result = []
      sorted.each do |gem_block|
        result.concat(gem_block[:comments]) unless gem_block[:comments].empty?
        result << gem_block[:gem_line]
      end

      result
    end

    def get_summary(gem_name, remote)
      source = remote ? "-r" : "-l"
      output = `gem list -d #{source} -e #{gem_name}`
      if output.include?(gem_name)
        summary = output.split("\n").last.strip
        summary
      else
        return get_summary(gem_name, true) unless remote
        nil
      end
    rescue StandardError => e
      nil
    end

    def fetch_gemfile_text(gem_name, version, original)
      base_url = "https://rubygems.org/gems/#{gem_name.strip}"
      url = URI(version ? "#{base_url}/versions/#{version.strip}" : base_url)

      begin
        response = Net::HTTP.get(url)
        unless response
          raise "Error: Could not fetch gem information from RubyGems for #{gem_name} version #{version}."
        end
        match = response.match(/<input[^>]*id=["']gemfile_text["'][^>]*value=["']([^"']+)["']/)

        if match
          CGI.unescapeHTML(match[1])
        else
          raise "Error: Could not extract Gemfile text for #{gem_name} version #{version}."
        end

      rescue => e
        puts e.message

        original
      end
    end

    def fetch_versions_from_lockfile(lockfile_path)
      return {} unless File.exist?(lockfile_path)
    
      versions = {}
      inside_specs = false
    
      File.readlines(lockfile_path).each do |line|
        line.strip!

        if line == "specs:"
          inside_specs = true
          next
        end

        inside_specs = false if inside_specs && line.empty?

        if inside_specs && line =~ /^([^\s]+)\s\(([^)]+)\)$/
          gem_name, gem_version = $1, $2
          gem_version = gem_version.match(/(\d+\.\d+\.\d+)/)[0] if gem_version =~ /(\d+\.\d+\.\d+)/
          versions[gem_name] = gem_version
        end
      end
      versions
    end

  end
end