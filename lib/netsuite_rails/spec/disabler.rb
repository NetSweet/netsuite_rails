module NetSuiteRails
  module Spec
    module TestDisabler

      def disable_netsuite_communication
        before do
          @_push_disabled = NetSuiteRails::Configuration.netsuite_push_disabled
          @_pull_disabled = NetSuiteRails::Configuration.netsuite_pull_disabled

          NetSuiteRails::Configuration.netsuite_push_disabled true
          NetSuiteRails::Configuration.netsuite_pull_disabled true
        end

        after do
          NetSuiteRails::Configuration.netsuite_push_disabled @_push_disabled
          NetSuiteRails::Configuration.netsuite_pull_disabled @_pull_disabled
        end
      end


    end
  end
end

RSpec.configure do |config|
  config.extend NetSuiteRails::Spec::TestDisabler
end