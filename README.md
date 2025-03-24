<p align="center">
  <img src="https://i.imgur.com/WHOyL9W.png" width="150" alt="GemSorter Logo">
</p>

# GemSorter

GemSorter is a simple gem to sort the contents of your Gemfile alphabetically while preserving comments and group structure. It helps maintain a clean and organized Gemfile.

## Features
* Sorts gems alphabetically.
* Preserves comments and their association with gems.
* Maintains group structure in the Gemfile.
* Optionally creates a backup of the original Gemfile.
* Update the comments of the gems based on their descriptions.
* Optionally converts single quotes to double quotes in gem declarations.

## Installation
Add the gem to your project's `Gemfile`:

```ruby
gem "gem_sorter"
```
or install it globally:

```bash
gem install gem_sorter
```

## Usage
Once installed, you can use the provided Rake task to sort your Gemfile:

```bash
rake gemfile:sort
```

You can also run the gem_sorter globally, without needing to add it to your Gemfile:

```bash
rake -r gem_sorter gemfile:sort
```

### Options
* `backup`: Pass `true` to create a backup of your Gemfile as `Gemfile.old` before sorting.
* `update_comments`: Pass `true` to update the comments of the gems based on their descriptions.
* `update_versions`: Pass `true` to update the versions of the gems based on the lockfile.
* `use_double_quotes`: Pass `true` to convert single quotes to double quotes in gem declarations.

Example:

```bash
rake gemfile:sort[true,true,true,true]
```
This will sort your Gemfile, create a backup, update comments and versions, and convert single quotes to double quotes.

### Options File
Create a file in the root of your project called `gem_sorter.yml`
* `backup`: Pass `true` to create a backup of your Gemfile as `Gemfile.old` before sorting.
* `update_comments`: Pass `true` to update the comments of the gems based on their descriptions.
* `update_versions`: Pass `true` to update the versions of the gems based on the lockfile.
* `use_double_quotes`: Pass `true` to convert single quotes to double quotes in gem declarations.
* `ignore_gems`: Pass an array of GEMs you want to ignore versions and comments
* `ignore_gem_versions`: Pass an array of GEMs you want to ignore versions
* `ignore_gem_comments`: Pass an array of GEMs you want to ignore comments

Example:

```yaml
backup: true
update_comments: true
update_versions: false
use_double_quotes: true
ignore_gems:
  - byebug
  - discard
ignore_gem_versions:
  - rspec
ignore_gem_comments:
  - otpor
```
This will sort your Gemfile, create a backup, update comments, and ignore specific gems for different operations.

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
