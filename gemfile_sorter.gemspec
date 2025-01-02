require_relative 'lib/gemfile_sorter/version'

Gem::Specification.new do |spec|
  spec.name          = 'gemfile_sorter'
  spec.version       = GemfileSorter::VERSION
  spec.authors       = ['Renan Garcia']
  spec.email         = ['email@renangarcia.me']
  spec.summary       = 'Sort gems in the Gemfile alphabetically'
  spec.description   = 'A simple gem to sort the gems in your Gemfile while preserving comments and groups'
  spec.homepage      = 'https://github.com/renan-garcia/gemfile_sorter'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 2.6.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage

  spec.files = Dir['lib/**/*', 'README.md', 'LICENSE.txt']
  spec.require_paths = ['lib']

  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
