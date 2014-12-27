require 'spec_helper'

require 'netsuite_rails/spec/spec_helper'

describe NetSuiteRails::TestHelpers do
  include NetSuiteRails::TestHelpers
  include ExampleModels

  let(:fake_search_results) { OpenStruct.new(results: [ OpenStruct.new(internal_id: 0) ]) }

  before do
    allow(NetSuite::Records::Customer).to receive(:search).and_return(fake_search_results)
    allow(NetSuite::Records::Customer).to receive(:get)
  end

  it "should accept a standard NS gem object" do
    get_last_netsuite_object(NetSuite::Records::Customer)

    expect(NetSuite::Records::Customer).to have_received(:search)
    expect(NetSuite::Records::Customer).to have_received(:get)
  end

  it "should accept a record sync enabled object" do
    get_last_netsuite_object(StandardRecord.new)

    expect(NetSuite::Records::Customer).to have_received(:search)
    expect(NetSuite::Records::Customer).to have_received(:get)
  end
end