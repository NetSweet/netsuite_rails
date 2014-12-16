require 'rails/generators'
require 'rails/generators/migration'
require 'rails/generators/active_record'

module NetsuiteRails
  module Generators
    class InstallGenerator < Rails::Generators::Base
      # http://stackoverflow.com/questions/4141739/generators-and-migrations-in-plugins-rails-3
      include ActiveRecord::Generators::Migration

      source_root File.expand_path('../templates', __FILE__)

      def copy_migration
        migration_template "create_netsuite_poll_timestamps.rb", "db/migrate/create_netsuite_poll_timestamps.rb"
      end

    end
  end
end
