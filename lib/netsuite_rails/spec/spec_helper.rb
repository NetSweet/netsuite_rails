require 'netsuite'
require 'savon/mock/spec_helper'

require 'netsuite_rails/spec/query_helpers'
require 'netsuite_rails/spec/disabler'

RSpec.configure do |config|
  config.include Savon::SpecHelper
end
