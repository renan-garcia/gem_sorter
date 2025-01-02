require 'spec_helper'
require 'gem_sorter'
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

  before do
    FileUtils.mkdir_p('spec/fixtures')
  end

  after do
    File.delete(temp_gemfile_path) if File.exist?(temp_gemfile_path)
  end

  it 'sorts the Gemfile content alphabetically while preserving comments and groups' do
    File.write(temp_gemfile_path, gemfile_content)
    sorter = described_class.new(temp_gemfile_path)
    sorted_content = sorter.sort
    expect(sorted_content.strip).to eq(expected_sorted_content.strip)
  end

  it 'sorts a complex and messy Gemfile with comments alphabetically while preserving comments and groups' do
    File.write(temp_gemfile_path, complex_gemfile_content)
    sorter = described_class.new(temp_gemfile_path)
    sorted_content = sorter.sort
    expect(sorted_content.strip).to eq(expected_complex_sorted_content.strip)
  end
end
