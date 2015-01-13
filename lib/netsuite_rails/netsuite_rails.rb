require 'netsuite'

require 'netsuite_rails/configuration'
require 'netsuite_rails/poll_timestamp'
require 'netsuite_rails/transformations'
require 'netsuite_rails/url_helper'

require 'netsuite_rails/poll_trigger'
require 'netsuite_rails/sync_trigger'
require 'netsuite_rails/sub_list_sync'

require 'netsuite_rails/record_sync'
require 'netsuite_rails/record_sync/poll_manager'
require 'netsuite_rails/record_sync/pull_manager'
require 'netsuite_rails/record_sync/push_manager'

require 'netsuite_rails/list_sync'
require 'netsuite_rails/list_sync/poll_manager'

module NetSuiteRails

  def self.rails4?
    Rails::VERSION::MAJOR >= 4
  end

  class Railtie < ::Rails::Railtie
    rake_tasks do
      load 'netsuite_rails/tasks/netsuite.rb'
    end

    config.before_configuration do
      require 'netsuite_rails/netsuite_configure'
    end
  end

end
