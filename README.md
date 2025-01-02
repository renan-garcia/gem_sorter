# GemSorter

GemSorter is a simple gem to sort the contents of your Gemfile alphabetically while preserving comments and group structure. It helps maintain a clean and organized Gemfile.

## Features
* Sorts gems alphabetically.
* Preserves comments and their association with gems.
* Maintains group structure in the Gemfile.
* Optionally creates a backup of the original Gemfile.

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

Example:

```bash
rake gemfile:sort[true]
```

This will sort your Gemfile and create a backup.

## Example
### Input Gemfile
```ruby
source "https://rubygems.org"

# Framework
gem "rails"
# Web server
gem "puma"

group :development do
  gem "pry"
  gem "dotenv-rails"
end
```

### Output Gemfile
```ruby
source "https://rubygems.org"

# Web server
gem "puma"
# Framework
gem "rails"

group :development do
  gem "dotenv-rails"
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
