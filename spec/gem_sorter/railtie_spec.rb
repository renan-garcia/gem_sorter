require 'spec_helper'
require 'open3'

# These specs exercise how `require 'gem_sorter'` decides to register the
# `gemfile:sort` rake task. The decision happens at require time, so each
# scenario runs in a fresh subprocess to get a clean load state (the test
# process itself has already required the gem).
RSpec.describe 'gem_sorter task registration' do
  def run_ruby(script)
    lib_path = File.expand_path('../../lib', __dir__)
    stdout, stderr, status = Open3.capture3('ruby', '-I', lib_path, '-e', script)
    "#{stdout}#{stderr}".tap { |output| expect(status).to be_success, output }
  end

  it 'registers the task via a Railtie when Rails is present' do
    script = <<~RUBY
      # Pretend `rails/railtie` is already loaded (as it is inside a Rails app)
      # so the gem does not try to pull in the full Rails stack here.
      $LOADED_FEATURES << 'rails/railtie.rb'
      module Rails
        class Railtie
          def self.rake_tasks(&blk); (@@blocks ||= []) << blk; end
          def self.blocks; @@blocks ||= []; end
        end
      end

      require 'gem_sorter'
      raise 'Railtie not loaded' unless defined?(GemSorter::Railtie)

      require 'rake'
      GemSorter::Railtie.blocks.each(&:call)
      puts Rake.application.tasks.map(&:name).grep(/gemfile/).inspect
    RUBY

    expect(run_ruby(script)).to include('gemfile:sort')
  end

  it 'loads the task directly when used standalone with Rake (no Rails)' do
    script = <<~RUBY
      require 'rake'
      require 'gem_sorter'
      raise 'Railtie should not be defined without Rails' if defined?(GemSorter::Railtie)
      puts Rake.application.tasks.map(&:name).grep(/gemfile/).inspect
    RUBY

    expect(run_ruby(script)).to include('gemfile:sort')
  end

  it 'loads without errors and without Rake during a plain require (e.g. app boot)' do
    script = <<~RUBY
      require 'gem_sorter'
      puts(defined?(Rake) ? 'rake-defined' : 'no-rake')
      puts(defined?(GemSorter::Sorter) ? 'sorter-ok' : 'sorter-missing')
    RUBY

    output = run_ruby(script)
    expect(output).to include('no-rake')
    expect(output).to include('sorter-ok')
  end
end
