require 'gem_sorter'

namespace :gemfile do
  desc 'Sort gems in Gemfile alphabetically. Options: [backup=true|false] [update_comments=true|false] [update_versions=true|false]'
  task :sort, [:backup, :update_comments, :update_versions] do |_t, args|
    args.with_defaults(
      backup: 'false',
      update_comments: 'false',
      update_versions: 'false'
    )
    
    gemfile_path = 'Gemfile'

    if File.exist?(gemfile_path)
      if args.backup.downcase == 'true'
        FileUtils.cp(gemfile_path, "#{gemfile_path}.old")
        puts 'Original Gemfile backed up as Gemfile.old'
      end

      sorter = ::GemSorter::Sorter.new(gemfile_path)
      sorted_content = sorter.sort(args.update_comments.downcase == 'true', args.update_versions.downcase == 'true')

      File.write(gemfile_path, sorted_content)

      puts 'Gemfile sorted successfully!'
    else
      puts 'Error: Gemfile not found in current directory'
    end
  end
end