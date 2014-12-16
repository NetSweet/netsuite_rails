require 'netsuite_rails/poll_timestamp'
require 'netsuite_rails/transformations'
require 'netsuite_rails/poll_manager'
require 'netsuite_rails/sync_trigger'
require 'netsuite_rails/sub_list_sync'
require 'netsuite_rails/record_sync'
require 'netsuite_rails/record_sync/pull_manager'
require 'netsuite_rails/record_sync/push_manager'
require 'netsuite_rails/list_sync'
require 'netsuite_rails/list_sync/pull_manager'
require 'netsuite_rails/url_helper'

module NetSuiteRails

  class Railtie < ::Rails::Railtie
    rake_tasks do
      load 'netsuite_rails/tasks/netsuite.rb'
    end
  end

end
