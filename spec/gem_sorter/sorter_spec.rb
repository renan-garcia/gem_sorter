require 'spec_helper'
require 'gem_sorter'
require 'task_config'
require 'fileutils'
require 'debug'

RSpec.describe GemSorter::Sorter do
  let(:gemfile_content) do
    <<~GEMFILE
      source "https://rubygems.org"

      # Comment for gem A
      gem "a_gem"
      gem "b_gem", group: :development
      gem "c_gem", "~> 2.0"

      group :test do
        gem "rspec"
        gem "faker"
      end
    GEMFILE
  end

  let(:expected_sorted_content) do
    <<~GEMFILE
      source "https://rubygems.org"

      # Comment for gem A
      gem "a_gem"
      gem "b_gem", group: :development
      gem "c_gem", "~> 2.0"

      group :test do
        gem "faker"
        gem "rspec"
      end
    GEMFILE
  end

  let(:complex_gemfile_content) do
    <<~GEMFILE
      source "https://rubygems.org"

      # Rails framework
      gem "rails", "6.1.4.1"
      # Puma for web server
      gem "puma", "~> 5.3"
      # Webpacker for JavaScript management
      gem "webpacker", "5.4.0"
      gem "turbolinks", "~> 5"
      gem "jbuilder", "~> 2.7"
      gem "sass-rails", ">= 6"
      # Authentication
      gem "devise"
      gem "pg", ">= 0.18", "< 2.0"
      gem "simple_form"
      # Parsing HTML
      gem "nokogiri"

      group :development, :test do
        gem "rspec-rails"
        gem "pry"
        gem "factory_bot_rails"
        gem "faker"
      end

      group :test do
        gem "capybara"
        gem "selenium-webdriver"
        gem "webdrivers"
      end
    GEMFILE
  end

  let(:expected_complex_sorted_content) do
    <<~GEMFILE
      source "https://rubygems.org"

      # Authentication
      gem "devise"
      gem "jbuilder", "~> 2.7"
      # Parsing HTML
      gem "nokogiri"
      gem "pg", ">= 0.18", "< 2.0"
      # Puma for web server
      gem "puma", "~> 5.3"
      # Rails framework
      gem "rails", "6.1.4.1"
      gem "sass-rails", ">= 6"
      gem "simple_form"
      gem "turbolinks", "~> 5"
      # Webpacker for JavaScript management
      gem "webpacker", "5.4.0"

      group :development, :test do
        gem "factory_bot_rails"
        gem "faker"
        gem "pry"
        gem "rspec-rails"
      end

      group :test do
        gem "capybara"
        gem "selenium-webdriver"
        gem "webdrivers"
      end
    GEMFILE
  end

  let(:gemfile_with_single_quotes) do
    <<~GEMFILE
      source 'https://rubygems.org'

      # Comment for gem A
      gem 'a_gem'
      gem 'b_gem', group: :development
      gem 'c_gem', '~> 2.0'
      # Comment with a 'quoted string' inside
      gem 'quoted_gem' # Inline comment with 'quotes'

      group :test do
        gem 'rspec'
        gem 'faker'
      end
    GEMFILE
  end

  let(:expected_double_quotes_content) do
    <<~GEMFILE
      source 'https://rubygems.org'

      # Comment for gem A
      gem "a_gem"
      gem "b_gem", group: :development
      gem "c_gem", "~> 2.0"
      # Comment with a 'quoted string' inside
      gem "quoted_gem" # Inline comment with 'quotes'

      group :test do
        gem "rspec"
        gem "faker"
      end
    GEMFILE
  end

  let(:temp_gemfile_path) { 'spec/fixtures/temp_gemfile' }
  let(:temp_lockfile_path) { 'spec/fixtures/temp_gemfile.lock' }

  before do
    FileUtils.mkdir_p('spec/fixtures')
  end

  after do
    File.delete(temp_gemfile_path) if File.exist?(temp_gemfile_path)
    File.delete(temp_lockfile_path) if File.exist?(temp_lockfile_path)
  end

  it 'sorts the Gemfile content alphabetically while preserving comments and groups' do
    File.write(temp_gemfile_path, gemfile_content)
    task_config = GemSorter::TaskConfig.new(gemfile_path: temp_gemfile_path)
    sorter = described_class.new(task_config)
    sorted_content = sorter.sort
    expect(sorted_content.strip).to eq(expected_sorted_content.strip)
  end

  it 'converts single quotes to double quotes when use_double_quotes is true' do
    File.write(temp_gemfile_path, gemfile_with_single_quotes)
    task_config = GemSorter::TaskConfig.new(gemfile_path: temp_gemfile_path, use_double_quotes: 'true')
    sorter = described_class.new(task_config)
    result = sorter.sort

    expect(result).to include('gem "a_gem"')
    expect(result).to include('gem "b_gem"')
    expect(result).to include('gem "c_gem"')
    expect(result).to include('gem "quoted_gem"')
    
    expect(result).to include("# Comment with a 'quoted string' inside")
    expect(result).to include("# Inline comment with 'quotes'")
    
    expect(result).to include('source "https://rubygems.org"')
  end

  it 'sorts a complex and messy Gemfile with comments alphabetically while preserving comments and groups' do
    File.write(temp_gemfile_path, complex_gemfile_content)
    task_config = GemSorter::TaskConfig.new(gemfile_path: temp_gemfile_path)
    sorter = described_class.new(task_config)
    sorted_content = sorter.sort
    expect(sorted_content.strip).to eq(expected_complex_sorted_content.strip)
  end

  it 'updates gem comments based on gem summaries when update_comments is true' do
    allow_any_instance_of(GemSorter::Sorter).to receive(:get_summary).and_return("Sample gem description")
    
    File.write(temp_gemfile_path, gemfile_content)
    task_config = GemSorter::TaskConfig.new(gemfile_path: temp_gemfile_path, update_comments: true)
    sorter = described_class.new(task_config)
    sorted_content = sorter.sort
    
    expect(sorted_content).to include("# Sample gem description")
  end

  it 'raises an error when the file does not exist' do
    non_existent_path = 'spec/fixtures/non_existent_gemfile'
    task_config = GemSorter::TaskConfig.new(gemfile_path: non_existent_path)
    expect { described_class.new(task_config) }.to raise_error(Errno::ENOENT)
  end

  it 'handles unusual nested groups correctly' do
    unusual_gemfile_content = <<~GEMFILE
      source "https://rubygems.org"

      group :development do
        group :sub_group do
          gem "nested_gem"
        end
      end
    GEMFILE

    File.write(temp_gemfile_path, unusual_gemfile_content)
    task_config = GemSorter::TaskConfig.new(gemfile_path: temp_gemfile_path)
    sorter = described_class.new(task_config)
    sorted_content = sorter.sort
    expect(sorted_content).to include('gem "nested_gem"')
  end

  it 'updates gem versions based on the lockfile when update_versions is true' do
    lockfile_content = <<~LOCKFILE
      GEM
        remote: https://rubygems.org/
        specs:
          rails (8.0.0)
          sinatra (4.1.0)
          faker (3.5.0)
    LOCKFILE

    gemfile_real_content = <<~GEMFILE
      source "https://rubygems.org"

      # Comment for gem A
      gem "rails"
      gem "sinatra", group: :development

      group :test do
        gem "rspec"
        gem "faker"
      end
    GEMFILE

    File.write(temp_gemfile_path, gemfile_real_content)
    File.write(temp_lockfile_path, lockfile_content)

    task_config = GemSorter::TaskConfig.new(gemfile_path: temp_gemfile_path, update_versions: true)

    sorter = described_class.new(task_config)
    sorted_content = sorter.sort

    expect(sorted_content).to include("gem 'rails', '~> 8.0'")
    expect(sorted_content).to include("gem 'sinatra', '~> 4.1'")
    expect(sorted_content).to include('gem "faker"')
  end

  it 'without mock adds the correct comment for gem "rails" when update_comments is true' do    
    simple_gemfile_content = <<~GEMFILE
      source "https://rubygems.org"

      gem "rails"
    GEMFILE

    expected_simple_sorted_content = <<~GEMFILE
      source "https://rubygems.org"

      # Full-stack web application framework.
      gem "rails"
    GEMFILE

    File.write(temp_gemfile_path, simple_gemfile_content)
    task_config = GemSorter::TaskConfig.new(gemfile_path: temp_gemfile_path, update_comments: true)
    sorter = described_class.new(task_config)
    sorted_content = sorter.sort

    expect(sorted_content.strip).to eq(expected_simple_sorted_content.strip)
  end  

  it 'sorts gems with similar names correctly' do
    similar_gemfile_content = <<~GEMFILE
      source "https://rubygems.org"

      gem "rails_admin"
      gem "rails"
    GEMFILE

    File.write(temp_gemfile_path, similar_gemfile_content)
    task_config = GemSorter::TaskConfig.new(gemfile_path: temp_gemfile_path)
    sorter = described_class.new(task_config)
    sorted_content = sorter.sort

    expect(sorted_content.strip).to eq(<<~GEMFILE.strip)
      source "https://rubygems.org"

      gem "rails"
      gem "rails_admin"
    GEMFILE
  end


  it 'ignores GEM comments correctly' do
    similar_gemfile_content = <<~GEMFILE
      source "https://rubygems.org"

      gem "rails_admin"
      gem "rails"
    GEMFILE

    File.write(temp_gemfile_path, similar_gemfile_content)
    task_config = GemSorter::TaskConfig.new(gemfile_path: temp_gemfile_path, update_comments: true, ignore_gem_comments: ['rails_admin'])
    sorter = described_class.new(task_config)
    sorted_content = sorter.sort

    expect(sorted_content.strip).to eq(<<~GEMFILE.strip)
      source "https://rubygems.org"

      # Full-stack web application framework.
      gem "rails"
      gem "rails_admin"
    GEMFILE
  end


  it 'ignores GEM versions correctly' do
    lockfile_content = <<~LOCKFILE
      GEM
        remote: https://rubygems.org/
        specs:
          rails (8.0.0)
          sinatra (4.1.0)
          faker (3.4.2)
          rspec (3.12.0)
    LOCKFILE

    gemfile_real_content = <<~GEMFILE
      source "https://rubygems.org"

      # Comment for gem A
      gem "rails"
      gem "sinatra", group: :development

      group :test do
        gem "rspec"
        gem "faker"
      end
    GEMFILE

    File.write(temp_gemfile_path, gemfile_real_content)
    File.write(temp_lockfile_path, lockfile_content)

    task_config = GemSorter::TaskConfig.new(gemfile_path: temp_gemfile_path, update_versions: true, ignore_gem_versions: ['sinatra'])

    sorter = described_class.new(task_config)
    sorted_content = sorter.sort

    expect(sorted_content).to include("gem 'rails', '~> 8.0'")
    expect(sorted_content).to include('gem "sinatra", group: :development')
    expect(sorted_content).to include("gem 'faker', '~> 3.4'")
    expect(sorted_content).to include("gem 'rspec', '~> 3.12'")
  end

  it 'removes versions from gems when remove_versions is true' do
    gemfile_with_versions = <<~GEMFILE
      source "https://rubygems.org"

      gem "thruster", "~> 0.1.13", require: false
      gem "countries", "~> 7.1", ">= 7.1.1"
      gem "tzinfo-data", platforms: %i[ windows jruby ]
    GEMFILE

    expected_content = <<~GEMFILE
      source "https://rubygems.org"

      gem "countries"
      gem "thruster", require: false
      gem "tzinfo-data", platforms: %i[ windows jruby ]
    GEMFILE

    File.write(temp_gemfile_path, gemfile_with_versions)
    task_config = GemSorter::TaskConfig.new(gemfile_path: temp_gemfile_path, remove_versions: true)
    sorter = described_class.new(task_config)
    sorted_content = sorter.sort

    expect(sorted_content.strip).to eq(expected_content.strip)
  end

  it 'ignores gems when removing versions' do
    gemfile_with_versions = <<~GEMFILE
      source "https://rubygems.org"

      gem "thruster", "~> 0.1.13", require: false
      gem "countries", "~> 7.1", ">= 7.1.1"
      gem "tzinfo-data", platforms: %i[ windows jruby ]
    GEMFILE

    expected_content = <<~GEMFILE
      source "https://rubygems.org"

      gem "countries", "~> 7.1", ">= 7.1.1"
      gem "thruster", require: false
      gem "tzinfo-data", platforms: %i[ windows jruby ]
    GEMFILE

    File.write(temp_gemfile_path, gemfile_with_versions)
    task_config = GemSorter::TaskConfig.new(gemfile_path: temp_gemfile_path, remove_versions: true, ignore_gem_versions: ['countries'])
    sorter = described_class.new(task_config)
    sorted_content = sorter.sort

    expect(sorted_content.strip).to eq(expected_content.strip)
  end

  it 'preserves ruby version line after source line' do
    gemfile_with_ruby = <<~GEMFILE
      source "https://rubygems.org"
      ruby "3.4.5"

      gem "rails"
      gem "sinatra", group: :development

      group :test do
        gem "rspec"
        gem "faker"
      end
    GEMFILE

    expected_content = <<~GEMFILE
      source "https://rubygems.org"

      ruby "3.4.5"

      gem "rails"
      gem "sinatra", group: :development

      group :test do
        gem "faker"
        gem "rspec"
      end
    GEMFILE

    File.write(temp_gemfile_path, gemfile_with_ruby)
    task_config = GemSorter::TaskConfig.new(gemfile_path: temp_gemfile_path)
    sorter = described_class.new(task_config)
    sorted_content = sorter.sort

    expect(sorted_content.strip).to eq(expected_content.strip)
  end

  it 'preserves ruby version line with different formatting' do
    gemfile_with_ruby = <<~GEMFILE
      source "https://rubygems.org"
      ruby '3.4.5'

      gem "rails"
    GEMFILE

    expected_content = <<~GEMFILE
      source "https://rubygems.org"

      ruby '3.4.5'

      gem "rails"
    GEMFILE

    File.write(temp_gemfile_path, gemfile_with_ruby)
    task_config = GemSorter::TaskConfig.new(gemfile_path: temp_gemfile_path)
    sorter = described_class.new(task_config)
    sorted_content = sorter.sort

    expect(sorted_content.strip).to eq(expected_content.strip)
  end

  it 'moves ruby version line to correct position when misplaced' do
    gemfile_with_misplaced_ruby = <<~GEMFILE
      source "https://rubygems.org"

      gem "rails"
      gem "sinatra", group: :development

      group :test do
        gem "faker"
        gem "rspec"
      end

      ruby "3.4.5"
    GEMFILE

    expected_content = <<~GEMFILE
      source "https://rubygems.org"

      ruby "3.4.5"

      gem "rails"
      gem "sinatra", group: :development

      group :test do
        gem "faker"
        gem "rspec"
      end
    GEMFILE

    File.write(temp_gemfile_path, gemfile_with_misplaced_ruby)
    task_config = GemSorter::TaskConfig.new(gemfile_path: temp_gemfile_path)
    sorter = described_class.new(task_config)
    sorted_content = sorter.sort

    expect(sorted_content.strip).to eq(expected_content.strip)
  end

  describe 'force_update' do
    let(:gemfile_with_versions) do
      <<~GEMFILE
        source "https://rubygems.org"

        gem "rails", "~> 7.0"
        gem "sinatra", "~> 2.0", group: :development
        gem "faker"
      GEMFILE
    end

    before do
      # Mock RubyGems API response for latest versions
      allow_any_instance_of(GemSorter::Sorter).to receive(:fetch_latest_version).and_return(nil)
      allow_any_instance_of(GemSorter::Sorter).to receive(:fetch_latest_version).with('rails').and_return('8.0.0')
      allow_any_instance_of(GemSorter::Sorter).to receive(:fetch_latest_version).with('sinatra').and_return('4.1.0')
      allow_any_instance_of(GemSorter::Sorter).to receive(:fetch_latest_version).with('faker').and_return('3.5.0')

      # Mock fetch_gemfile_text to return proper Gemfile format
      allow_any_instance_of(GemSorter::Sorter).to receive(:fetch_gemfile_text).and_return(nil)
      allow_any_instance_of(GemSorter::Sorter).to receive(:fetch_gemfile_text).with('rails', '8.0.0', anything).and_return("gem 'rails', '~> 8.0'")
      allow_any_instance_of(GemSorter::Sorter).to receive(:fetch_gemfile_text).with('sinatra', '4.1.0', anything).and_return("gem 'sinatra', '~> 4.1'")
      allow_any_instance_of(GemSorter::Sorter).to receive(:fetch_gemfile_text).with('faker', '3.5.0', anything).and_return("gem 'faker', '~> 3.5'")
    end

    it 'updates gems to latest versions from RubyGems when force_update is true' do
      File.write(temp_gemfile_path, gemfile_with_versions)
      task_config = GemSorter::TaskConfig.new(gemfile_path: temp_gemfile_path, force_update: true)
      sorter = described_class.new(task_config)

      sorted_content = nil
      expect { sorted_content = sorter.sort }.to output(/The following gems were updated:/).to_stdout

      expect(sorted_content).to include("gem 'rails', '~> 8.0'")
      expect(sorted_content).to include("gem 'sinatra', '~> 4.1', group: :development")
      expect(sorted_content).to include("gem 'faker', '~> 3.5'")
    end

    it 'prints version update summary when gems are updated' do
      File.write(temp_gemfile_path, gemfile_with_versions)
      task_config = GemSorter::TaskConfig.new(gemfile_path: temp_gemfile_path, force_update: true)
      sorter = described_class.new(task_config)

      expect { sorter.sort }.to output(
        /The following gems were updated:.*Run `bundle install` to install the updated gems\./m
      ).to_stdout
    end

    it 'prints correct version information in update summary' do
      File.write(temp_gemfile_path, gemfile_with_versions)
      task_config = GemSorter::TaskConfig.new(gemfile_path: temp_gemfile_path, force_update: true)
      sorter = described_class.new(task_config)

      expect { sorter.sort }.to output(
        /rails.*8\.0\.0.*sinatra.*4\.1\.0/m
      ).to_stdout
    end

    it 'ignores gems in ignore_gem_versions when force_update is true' do
      File.write(temp_gemfile_path, gemfile_with_versions)
      task_config = GemSorter::TaskConfig.new(
        gemfile_path: temp_gemfile_path,
        force_update: true,
        ignore_gem_versions: ['sinatra']
      )
      sorter = described_class.new(task_config)
      sorted_content = sorter.sort

      expect(sorted_content).to include("gem 'rails', '~> 8.0'")
      expect(sorted_content).to include('gem "sinatra", "~> 2.0", group: :development')
      expect(sorted_content).to include("gem 'faker', '~> 3.5'")
    end

    it 'ignores gems in ignore_gems when force_update is true' do
      File.write(temp_gemfile_path, gemfile_with_versions)
      task_config = GemSorter::TaskConfig.new(
        gemfile_path: temp_gemfile_path,
        force_update: true,
        ignore_gems: ['sinatra']
      )
      sorter = described_class.new(task_config)
      sorted_content = sorter.sort

      expect(sorted_content).to include("gem 'rails', '~> 8.0'")
      expect(sorted_content).to include('gem "sinatra", "~> 2.0", group: :development')
      expect(sorted_content).to include("gem 'faker', '~> 3.5'")
    end

    it 'preserves other gem parameters when force_update is true' do
      gemfile_with_params = <<~GEMFILE
        source "https://rubygems.org"

        gem "rails", "~> 7.0", require: false
        gem "sinatra", "~> 2.0", group: :development, platforms: [:ruby]
      GEMFILE

      File.write(temp_gemfile_path, gemfile_with_params)
      task_config = GemSorter::TaskConfig.new(gemfile_path: temp_gemfile_path, force_update: true)
      sorter = described_class.new(task_config)
      sorted_content = sorter.sort

      expect(sorted_content).to include("gem 'rails', '~> 8.0', require: false")
      expect(sorted_content).to include("gem 'sinatra', '~> 4.1', group: :development, platforms: [:ruby]")
    end

    it 'uses latest version from RubyGems API, ignoring lockfile' do
      lockfile_content = <<~LOCKFILE
        GEM
          remote: https://rubygems.org/
          specs:
            rails (7.1.0)
            sinatra (2.2.0)
      LOCKFILE

      File.write(temp_gemfile_path, gemfile_with_versions)
      File.write(temp_lockfile_path, lockfile_content)

      task_config = GemSorter::TaskConfig.new(gemfile_path: temp_gemfile_path, force_update: true)
      sorter = described_class.new(task_config)
      sorted_content = sorter.sort

      # Should use latest from API (8.0.0) not from lockfile (7.1.0)
      expect(sorted_content).to include("gem 'rails', '~> 8.0'")
      expect(sorted_content).not_to include("gem 'rails', '~> 7.1'")
    end

    it 'does not print update message when no gems are updated' do
      gemfile_without_versions = <<~GEMFILE
        source "https://rubygems.org"

        gem "rails"
        gem "sinatra"
      GEMFILE

      # Mock to return nil (gem not found or already at latest)
      allow_any_instance_of(GemSorter::Sorter).to receive(:fetch_latest_version).and_return(nil)
      allow_any_instance_of(GemSorter::Sorter).to receive(:fetch_gemfile_text).and_return(nil)

      File.write(temp_gemfile_path, gemfile_without_versions)
      task_config = GemSorter::TaskConfig.new(gemfile_path: temp_gemfile_path, force_update: true)
      sorter = described_class.new(task_config)

      expect { sorter.sort }.not_to output(/The following gems were updated:/).to_stdout
    end

    it 'handles gems in groups when force_update is true' do
      gemfile_with_groups = <<~GEMFILE
        source "https://rubygems.org"

        gem "rails", "~> 7.0"

        group :test do
          gem "rspec", "~> 3.0"
          gem "faker", "~> 2.0"
        end
      GEMFILE

      # Override mocks from before block for this specific test
      allow_any_instance_of(GemSorter::Sorter).to receive(:fetch_latest_version).and_call_original
      allow_any_instance_of(GemSorter::Sorter).to receive(:fetch_latest_version).with('rails').and_return('8.0.0')
      allow_any_instance_of(GemSorter::Sorter).to receive(:fetch_latest_version).with('rspec').and_return('3.13.0')
      allow_any_instance_of(GemSorter::Sorter).to receive(:fetch_latest_version).with('faker').and_return('3.5.0')
      
      allow_any_instance_of(GemSorter::Sorter).to receive(:fetch_gemfile_text).and_call_original
      allow_any_instance_of(GemSorter::Sorter).to receive(:fetch_gemfile_text).with('rails', '8.0.0', anything).and_return("gem 'rails', '~> 8.0'")
      allow_any_instance_of(GemSorter::Sorter).to receive(:fetch_gemfile_text).with('rspec', '3.13.0', anything).and_return("gem 'rspec', '~> 3.13'")
      allow_any_instance_of(GemSorter::Sorter).to receive(:fetch_gemfile_text).with('faker', '3.5.0', anything).and_return("gem 'faker', '~> 3.5'")

      File.write(temp_gemfile_path, gemfile_with_groups)
      task_config = GemSorter::TaskConfig.new(gemfile_path: temp_gemfile_path, force_update: true)
      sorter = described_class.new(task_config)
      sorted_content = sorter.sort

      expect(sorted_content).to include("gem 'rails', '~> 8.0'")
      expect(sorted_content).to include("gem 'rspec', '~> 3.13'")
      expect(sorted_content).to include("gem 'faker', '~> 3.5'")
    end

    it 'uses force_update instead of update_versions when both are true' do
      lockfile_content = <<~LOCKFILE
        GEM
          remote: https://rubygems.org/
          specs:
            rails (7.1.0)
      LOCKFILE

      gemfile_content = <<~GEMFILE
        source "https://rubygems.org"

        gem "rails"
      GEMFILE

      File.write(temp_gemfile_path, gemfile_content)
      File.write(temp_lockfile_path, lockfile_content)

      # Mock force_update to return latest version (8.0.0) instead of lockfile version (7.1.0)
      allow_any_instance_of(GemSorter::Sorter).to receive(:fetch_latest_version).with('rails').and_return('8.0.0')
      allow_any_instance_of(GemSorter::Sorter).to receive(:fetch_gemfile_text).with('rails', '8.0.0', anything).and_return("gem 'rails', '~> 8.0'")

      task_config = GemSorter::TaskConfig.new(
        gemfile_path: temp_gemfile_path,
        force_update: true,
        update_versions: true
      )
      sorter = described_class.new(task_config)
      sorted_content = sorter.sort

      # Should use latest from API (8.0.0) not from lockfile (7.1.0)
      expect(sorted_content).to include("gem 'rails', '~> 8.0'")
      expect(sorted_content).not_to include("gem 'rails', '~> 7.1'")
    end
  end
end