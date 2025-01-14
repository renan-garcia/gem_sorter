require 'spec_helper'
require 'gem_sorter'
require 'task_config'
require 'fileutils'

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
end