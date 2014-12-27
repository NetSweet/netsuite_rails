require 'spec_helper'

require 'netsuite_rails/spec/spec_helper'

describe NetSuiteRails::TestHelpers do
  include NetSuiteRails::TestHelpers
  
  it "should accept a standard NS gem object" do
    allow(NetSuite::Records::Customer).to receive(:search)
    allow(NetSuite::Records::Customer).to receive(:get)

    get_last_netsuite_object(NetSuite::Records::Customer)

    expect(NetSuite::Records::Customer).to have_received(:search)
    expect(NetSuite::Records::Customer).to have_received(:get)
  end

  it "should accept a record sync enabled object" do
    
  end
end