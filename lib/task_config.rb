require 'yaml'

module GemSorter
  class TaskConfig
    attr_reader :backup, :update_comments, :update_versions, :ignore_gems, :gemfile_path

    DEFAULT_CONFIG = {
      'backup' => false,
      'update_comments' => false,
      'update_versions' => false,
      'gemfile_path' => 'Gemfile',
      'ignore_gems' => [],
      'ignore_gem_versions' => [],
      'ignore_gem_comments' => []
    }.freeze

    def initialize(args = nil)
      @backup = nil
      @update_comments = nil
      @update_versions = nil
      @ignore_gems = nil
      @ignore_gem_versions = nil
      @ignore_gem_comments = nil
      @gemfile_path = nil
      load_config(args)
    end

    def backup
      @backup.nil? ? DEFAULT_CONFIG['backup'] : @backup
    end

    def update_comments
      @update_comments.nil? ? DEFAULT_CONFIG['update_comments'] : @update_comments
    end

    def update_versions
      @update_versions.nil? ? DEFAULT_CONFIG['update_versions'] : @update_versions
    end

    def ignore_gems
      @ignore_gems.nil? ? DEFAULT_CONFIG['ignore_gems'] : @ignore_gems
    end

    def ignore_gem_versions
      @ignore_gem_versions.nil? ? DEFAULT_CONFIG['ignore_gem_versions'] : @ignore_gem_versions
    end

    def ignore_gem_comments
      @ignore_gem_comments.nil? ? DEFAULT_CONFIG['ignore_gem_comments'] : @ignore_gem_comments
    end

    def gemfile_path
      @gemfile_path.nil? ? DEFAULT_CONFIG['gemfile_path'] : @gemfile_path
    end

    private

    def load_config(args)
      load_config_from_file
      load_config_from_args(args)
    end

    def load_config_from_file
      return unless File.exist?(gem_sorter_config_file_path)

      task_config = YAML.load_file(gem_sorter_config_file_path)
      @backup = task_config['backup'] if task_config.key?('backup')
      @update_comments = task_config['update_comments'] if task_config.key?('update_comments')
      @update_versions = task_config['update_versions'] if task_config.key?('update_versions')
      @gemfile_path = task_config['gemfile_path'] if task_config.key?('gemfile_path')
      @ignore_gems = task_config['ignore_gems'] if task_config.key?('ignore_gems')
      @ignore_gem_versions = task_config['ignore_gem_versions'] if task_config.key?('ignore_gem_versions')
      @ignore_gem_comments = task_config['ignore_gem_comments'] if task_config.key?('ignore_gem_comments')
    end

    def load_config_from_args(args)
      return unless args

      @backup = parse_boolean(args[:backup]) unless args[:backup].nil?
      @update_comments = parse_boolean(args[:update_comments]) unless args[:update_comments].nil?
      @update_versions = parse_boolean(args[:update_versions]) unless args[:update_versions].nil?
      @gemfile_path = args[:gemfile_path] unless args[:gemfile_path].nil?
      @ignore_gems = args[:ignore_gems] unless args[:ignore_gems].nil?
      @ignore_gem_versions = args[:ignore_gem_versions] unless args[:ignore_gem_versions].nil?
      @ignore_gem_comments = args[:ignore_gem_comments] unless args[:ignore_gem_comments].nil?
    end

    def parse_boolean(value)
      value.to_s.downcase == 'true'
    end

    def gem_sorter_config_file_path
      'gem_sorter.yml'
    end
  end
end
