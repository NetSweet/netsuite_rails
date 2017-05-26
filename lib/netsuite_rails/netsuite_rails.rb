require 'netsuite'

require 'netsuite_rails/errors'
require 'netsuite_rails/configuration'
require 'netsuite_rails/poll_timestamp' if defined?(::ActiveRecord)
require 'netsuite_rails/transformations'
require 'netsuite_rails/url_helper'

require 'netsuite_rails/poll_trigger'
require 'netsuite_rails/sync_trigger'
require 'netsuite_rails/sub_list_sync'

require 'netsuite_rails/record_sync'
require 'netsuite_rails/record_sync/poll_manager'
require 'netsuite_rails/record_sync/pull_manager'
require 'netsuite_rails/record_sync/push_manager'

require 'netsuite_rails/routines/company_contact_match'

require 'netsuite_rails/list_sync'
require 'netsuite_rails/list_sync/poll_manager'

module NetSuiteRails

  def self.rails4?
    ::Rails::VERSION::MAJOR >= 4
  end

  def self.configure_from_env(&block)
    self.configure do
      reset!

      netsuite_pull_disabled ENV['NETSUITE_PULL_DISABLED'].present? && ENV['NETSUITE_PULL_DISABLED'] == "true"
      netsuite_push_disabled ENV['NETSUITE_PUSH_DISABLED'].present? && ENV['NETSUITE_PUSH_DISABLED'] == "true"

      if ENV['NETSUITE_DISABLE_SYNC'].present? && ENV['NETSUITE_DISABLE_SYNC'] == "true"
        netsuite_pull_disabled true
        netsuite_push_disabled true
      end

      polling_page_size if ENV['NETSUITE_POLLING_PAGE_SIZE'].present?
    end

    self.configure(&block) if block
  end

  def self.configure(&block)
    NetSuiteRails::Configuration.instance_eval(&block)
  end

  class Railtie < ::Rails::Railtie
    rake_tasks do
      load 'netsuite_rails/tasks/netsuite.rb'
    end
  end

end
