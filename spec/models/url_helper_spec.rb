require 'spec_helper'

describe NetSuiteRails::UrlHelper do
	include ExampleModels

  it 'should handle a netsuite record' do
  	c = NetSuite::Records::Customer.new internal_id: 123
  	url = NetSuiteRails::UrlHelper.netsuite_url(c)

  	expect(url).to include("ent")
    expect(url).to include("123")
  end

  it "should handle a record sync enabled record" do
  	s = StandardRecord.new netsuite_id: 123
  	url = NetSuiteRails::UrlHelper.netsuite_url(s)

  	expect(url).to include("ent")
    expect(url).to include("123")
  end

  it "should handle a list sync enabled record" do
  	
  end
end
