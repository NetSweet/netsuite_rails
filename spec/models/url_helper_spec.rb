require 'spec_helper'

describe NetSuiteRails::UrlHelper do
	include ExampleModels

  it 'should handle a netsuite record' do
		NetSuite::Configuration.sandbox = true
  	c = NetSuite::Records::Customer.new internal_id: 123
  	url = NetSuiteRails::UrlHelper.netsuite_url(c)

		expect(url).to eq('https://system.sandbox.netsuite.com/app/common/entity/entity.nl?id=123')
  end

  it "should handle a record sync enabled record" do
		NetSuite::Configuration.sandbox = true
  	s = StandardRecord.new netsuite_id: 123
  	url = NetSuiteRails::UrlHelper.netsuite_url(s)

		expect(url).to eq('https://system.sandbox.netsuite.com/app/common/entity/entity.nl?id=123')
  end

  xit "should handle a list sync enabled record" do

  end

	it 'should change the prefix URL when a non-sandbox datacenter is in use' do
		NetSuite::Configuration.sandbox = false

		s = StandardRecord.new netsuite_id: 123
		url = NetSuiteRails::UrlHelper.netsuite_url(s)

		expect(url).to eq('https://system.netsuite.com/app/common/entity/entity.nl?id=123')
	end
end
