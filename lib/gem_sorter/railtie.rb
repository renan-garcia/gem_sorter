require 'rails/railtie'

module GemSorter
  # Registers the gem's rake tasks through the Rails task-loading pipeline.
  # Using a Railtie ensures the tasks are available reliably inside a Rails
  # application (under both `bin/rails` and `bin/rake`) without defining tasks
  # during `Bundler.require`, which is order-dependent and could break boot.
  class Railtie < Rails::Railtie
    rake_tasks do
      load File.expand_path('../tasks/gem_sorter.rake', __dir__)
    end
  end
end
