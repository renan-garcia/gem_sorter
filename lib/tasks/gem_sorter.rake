require 'gem_sorter'
require 'yaml'
require 'task_config'

namespace :gemfile do
  desc 'Sort gems in Gemfile alphabetically. Options: [backup=true|false] [update_comments=true|false] [update_versions=true|false]'
  task :sort, [:backup, :update_comments, :update_versions] do |_t, args|
    task_config = GemSorter::TaskConfig.new(args)
    
    if File.exist?(task_config.gemfile_path)
      if task_config.backup
        FileUtils.cp(task_config.gemfile_path, "#{task_config.gemfile_path}.old")
        puts 'Original Gemfile backed up as Gemfile.old'
      end

      sorter = ::GemSorter::Sorter.new(task_config)
      sorted_content = sorter.sort

      File.write(task_config.gemfile_path, sorted_content)

      puts 'Gemfile sorted successfully!'
    else
      puts 'Error: Gemfile not found in current directory'
    end
  end
end