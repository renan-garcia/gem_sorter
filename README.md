# GemSorter

GemSorter is a simple gem to sort the contents of your Gemfile alphabetically while preserving comments and group structure. It helps maintain a clean and organized Gemfile.

## Features
* Sorts gems alphabetically.
* Preserves comments and their association with gems.
* Maintains group structure in the Gemfile.
* Optionally creates a backup of the original Gemfile.
* Update the comments of the gems based on their descriptions.

## Installation
Add the gem to your project's `Gemfile`:

```ruby
gem "gem_sorter"
```

## Usage
Once installed, you can use the provided Rake task to sort your Gemfile:

```bash
rake gemfile:sort
```

### Options
* `backup`: Pass `true` to create a backup of your Gemfile as `Gemfile.old` before sorting.
* `update_comments`: Pass `true` to update the comments of the gems based on their descriptions.
* `update_versions`: Pass `true` to update the versions of the gems based on the lockfile.

Example:

```bash
rake gemfile:sort[true,true,true]
```

This will sort your Gemfile, create a backup, and update comments and versions.

## Example
### Input Gemfile
```ruby
source "https://rubygems.org"

# Framework
gem "rails"
gem "puma", "~> 5.3"

group :development do
  gem "dotenv-rails"
  gem "pry"
end
```

### Output Gemfile
```ruby
source "https://rubygems.org"

# A Ruby/Rack web server built for parallelism.
gem "puma", "~> 5.3"
# Full-stack web application framework.
gem "rails", "~> 8.0", ">= 8.0.1"

group :development do
  # Autoload dotenv in Rails.
  gem 'dotenv-rails', '~> 3.1', '>= 3.1.7'
  # A runtime developer console and IRB alternative with powerful introspection capabilities.
  gem "pry"
end
```

## Development
To contribute to this project:

1. Clone the repository:
   ```bash
   git clone https://github.com/renan-garcia/gem_sorter.git
   ```
2. Navigate to the project directory:
   ```bash
   cd gem_sorter
   ```
3. Install dependencies:
   ```bash
   bundle install
   ```
4. Run the tests:
   ```bash
   rspec
   ```

## Contributing
We welcome contributions! Here's how you can help:

1. Fork the repository.
2. Create a feature branch:
   ```bash
   git checkout -b feature/my-new-feature
   ```
3. Commit your changes:
   ```bash
   git commit -m "Add a new feature"
   ```
4. Push to the branch:
   ```bash
   git push origin feature/my-new-feature
   ```
5. Open a pull request.

## Acknowledgments
Special thanks to the Ruby community for their guidance and support!
