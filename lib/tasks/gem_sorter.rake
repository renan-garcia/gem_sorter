require 'gem_sorter'

namespace :gemfile do
  desc 'Sort gems in Gemfile alphabetically'
  task :sort, [:backup] do |_t, args|
    args.with_defaults(backup: 'false')
    gemfile_path = 'Gemfile'

    if File.exist?(gemfile_path)
      if args.backup.downcase == 'true'
        FileUtils.cp(gemfile_path, "#{gemfile_path}.old")
        puts 'Original Gemfile backed up as Gemfile.old'
      end

      sorter = Gem::Sorter.new(gemfile_path)
      sorted_content = sorter.sort

      File.write(gemfile_path, sorted_content)

      puts 'Gemfile sorted successfully!'
    else
      puts 'Error: Gemfile not found in current directory'
    end
  end
end
