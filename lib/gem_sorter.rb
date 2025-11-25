# lib/gem_sorter.rb
require 'net/http'
require 'cgi'
require 'openssl'
require 'json'

load File.expand_path('tasks/gem_sorter.rake', __dir__) if defined?(Rake)

module GemSorter
  class Sorter
    def initialize(task_config)
      @config = task_config
      @filepath = task_config.gemfile_path
      @content = File.read(task_config.gemfile_path)
      @versions = nil
      @version_updates = []
    end

    def sort
      ruby_line = extract_ruby_line(@content)
      
      parts = @content.split(/^group/)
      main_section = parts.shift
      group_sections = parts

      source_line, gems, _ = process_main_section(main_section)

      update_gem_summaries(gems) if @config.update_comments
      if @config.force_update
        force_update_versions(gems)
      elsif @config.update_versions
        update_version_text(gems)
      end
      remove_versions(gems) if @config.remove_versions
      sorted_gems = sort_gem_blocks(gems)

      result = []
      result << source_line
      if ruby_line
        result << ''
        result << ruby_line
      end
      result << ''
      result.concat(sorted_gems)
      result << ''

      group_sections.each do |section|
        group_gems = process_group_section(section)
        update_gem_summaries(group_gems) if @config.update_comments
        if @config.force_update
          force_update_versions(group_gems)
        elsif @config.update_versions
          update_version_text(group_gems)
        end
        remove_versions(group_gems) if @config.remove_versions
        result << "group#{section.split("\n").first}"
        result.concat(sort_gem_blocks(group_gems).map { |line| "  #{line}" })
        result << 'end'
        result << ''
      end

      result = transform_to_double_quotes(result) if @config.use_double_quotes

      print_version_updates if @config.force_update && !@version_updates.empty?

      result.join("\n")
    end

    private

    def extract_ruby_line(content)
      lines = content.split("\n")
      ruby_line = lines.find { |line| line.strip.start_with?('ruby') }
      ruby_line&.strip
    end

    def transform_to_double_quotes(gem_file_content)
      return gem_file_content unless gem_file_content.is_a?(Array) || gem_file_content.is_a?(String)
      
      content = gem_file_content.is_a?(Array) ? gem_file_content : gem_file_content.split("\n")
      
      transformed_content = content.map do |line|
        next line if line.nil? || line.strip.empty?

        if line.strip.start_with?('#')
          line
        elsif line.include?('gem') && line =~ /gem\s+[']/
          begin
            parts = line.split('#', 2)
            main_part = parts[0]
            comment_part = parts[1]
            processed_main = main_part.gsub("'", '"')
            
            if comment_part
              "#{processed_main}##{comment_part}"
            else
              processed_main
            end
          rescue => e
            puts "Error transforming to double quotes: #{e.message}"
            line
          end
        elsif line.include?('source')
          line.gsub("'", '"')
        else
          line
        end
      end
      
      gem_file_content.is_a?(Array) ? transformed_content : transformed_content.join("\n")
    end

    def update_version_text(gems)
      @versions ||= fetch_versions_from_lockfile("#{@filepath}.lock")
      gems.each do |gem_block|
        gem_name =  extract_gem_name(gem_block[:gem_line])
        next if @config.ignore_gems.include?(gem_name) || @config.ignore_gem_versions.include?(gem_name)

        version = @versions[gem_name]
        extra_params = extract_params(gem_block[:gem_line])
        base = version ? "#{fetch_gemfile_text(gem_name, version, gem_block[:gem_line])}" : gem_block[:gem_line]
        if base != gem_block[:gem_line]
          gem_block[:gem_line] = [base.strip, extra_params].select { |value| !value.nil? && !value.empty? }.join(',')
        end
      end
    end

    def force_update_versions(gems)
      @versions ||= fetch_versions_from_lockfile("#{@filepath}.lock")
      
      gems.each do |gem_block|
        gem_name = extract_gem_name(gem_block[:gem_line])
        next if @config.ignore_gems.include?(gem_name) || @config.ignore_gem_versions.include?(gem_name)

        # Try to get current version from lockfile first, then from gem line
        current_version = @versions[gem_name] || extract_current_version(gem_block[:gem_line])
        latest_version = fetch_latest_version(gem_name)
        
        next unless latest_version

        extra_params = extract_params(gem_block[:gem_line])
        new_gemfile_text = fetch_gemfile_text(gem_name, latest_version, gem_block[:gem_line])
        
        next unless new_gemfile_text && new_gemfile_text != gem_block[:gem_line]
        
        gem_block[:gem_line] = [new_gemfile_text.strip, extra_params].select { |value| !value.nil? && !value.empty? }.join(',')
        
        # Track version update if version changed
        # Compare semantic versions (x.y.z) for accurate comparison
        current_semantic = current_version&.match(/(\d+\.\d+\.\d+)/)
        current_semantic = current_semantic ? current_semantic[1] : nil
        latest_semantic = latest_version.match(/(\d+\.\d+\.\d+)/)
        latest_semantic = latest_semantic ? latest_semantic[1] : nil
        
        if current_semantic != latest_semantic
          @version_updates << {
            gem_name: gem_name,
            from_version: current_version || 'no version specified',
            to_version: latest_version
          }
        end
      end
    end

    def remove_versions(gems)
      gems.each do |gem_block|
        gem_name =  extract_gem_name(gem_block[:gem_line])
        next if @config.ignore_gems.include?(gem_name) || @config.ignore_gem_versions.include?(gem_name)

        extra_params = extract_params(gem_block[:gem_line])
        base = gem_block[:gem_line].match(/gem\s+['"][^'"]+['"]/)[0]
        if extra_params
          gem_block[:gem_line] = "#{base},#{extra_params}"
        else
          gem_block[:gem_line] = base
        end
      end
    end

    def extract_params(gem_line)
      return nil unless gem_line =~ /gem\s+['"][^'"]+['"]/

      if gem_line =~ /gem\s+['"][^'"]+['"]\s*,\s*(.*)/
        additional_params = $1.strip
        return nil if additional_params.empty?
        params_with_colon = additional_params.scan(/(\w+:\s*[^,]+(?:,\s*[^,]+)*|\w+:\s*['"][^'"]+['"])/).flatten
        return " #{params_with_colon.join(', ')}" unless params_with_colon.empty?
      end
      nil
    end

    def update_gem_summaries(gems)
      gems.each do |gem_block|
        gem_name = extract_gem_name(gem_block[:gem_line])
        next if @config.ignore_gems.include?(gem_name) || @config.ignore_gem_comments.include?(gem_name)

        if summary = get_summary(gem_name, false)
          gem_block[:comments] = ["# #{summary}"]
        end
      end
    end

    def extract_gem_name(gem_line)
      gem_line.match(/gem\s+['"]([^'"]+)['"]/)[1]
    end

    def process_main_section(section)
      lines = section.split("\n").map(&:strip).reject(&:empty?)
      source_line = lines.shift

      gems = []
      ruby_line = nil
      current_comments = []

      lines.each do |line|
        if line.start_with?('#')
          current_comments << line
        elsif line.start_with?('ruby')
          ruby_line = line
        elsif line.start_with?('gem')
          gems << {
            comments: current_comments,
            gem_line: line
          }
          current_comments = []
        end
      end

      [source_line, gems, ruby_line]
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
    rescue StandardError
      nil
    end

    def fetch_gemfile_text(gem_name, version, original)
      base_url = "https://rubygems.org/gems/#{gem_name.strip}"
      url = URI(version ? "#{base_url}/versions/#{version.strip}" : base_url)

      begin
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        
        request = Net::HTTP::Get.new(url)
        response = http.request(request)
        
        unless response.is_a?(Net::HTTPSuccess)
          raise "Error: Could not fetch gem information from RubyGems for #{gem_name} version #{version}. Status: #{response.code}"
        end
        
        match = response.body.match(/<input[^>]*id=["']gemfile_text["'][^>]*value=["']([^"']+)["']/)

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

    def fetch_latest_version(gem_name)
      url = URI("https://rubygems.org/api/v1/gems/#{gem_name.strip}.json")

      begin
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        
        request = Net::HTTP::Get.new(url)
        response = http.request(request)
        
        unless response.is_a?(Net::HTTPSuccess)
          return nil
        end
        
        gem_data = JSON.parse(response.body)
        gem_data['version']
      rescue => e
        nil
      end
    end

    def extract_current_version(gem_line)
      # Try to extract version from gem line
      # Examples: gem "rails", "~> 7.0" or gem "rails", "7.0.0" or gem "rails", ">= 7.0", "< 8.0"
      # Match first version string after gem name
      version_match = gem_line.match(/gem\s+['"][^'"]+['"]\s*,\s*['"]([^'"]+)['"]/)
      return nil unless version_match
      
      version_string = version_match[1]
      # Extract semantic version (x.y.z) from version string, or return the full version string
      semantic_version = version_string.match(/(\d+\.\d+\.\d+)/)
      semantic_version ? semantic_version[1] : version_string
    end

    def print_version_updates
      return if @version_updates.empty?

      puts "\nThe following gems were updated:"
      @version_updates.each do |update|
        puts "  * #{update[:gem_name]} (#{update[:from_version]} -> #{update[:to_version]})"
      end
      puts "\nRun `bundle install` to install the updated gems."
      puts ""
    end

  end
end