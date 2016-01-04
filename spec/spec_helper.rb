# https://circleci.com/docs/code-coverage
if ENV['CIRCLE_ARTIFACTS']
  require 'simplecov'
  dir = File.join("../../../..", ENV['CIRCLE_ARTIFACTS'], "coverage")
  SimpleCov.coverage_dir(dir)
  SimpleCov.start
end

require 'rails/all'

require 'shoulda/matchers'
require 'rspec/rails'
require 'faker'
require 'pry'

require 'netsuite_rails'

Dir[File.join(File.dirname(__FILE__), "support/**/*.rb")].each {|f| require f }

TestApplication::Application.initialize!

# TODO use DB cleaner instead
NetSuiteRails::PollTimestamp.delete_all

RSpec.configure do |config|
  config.color = true

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.before do
    NetSuiteRails.configure do
      reset!
      netsuite_sync_mode :sync
    end

    NetSuite::Configuration.reset!
  end
end
