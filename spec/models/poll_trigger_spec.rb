require 'spec_helper'

describe NetSuiteRails::PollTrigger do
  include ExampleModels

  it "should properly sync for the first time" do
  	expect(StandardRecord).to receive(:netsuite_poll).with(hash_including(:import_all => true))

  	NetSuiteRails::PollTrigger.sync list_models: []
  end

  it "should trigger syncing when the time has passed is greater than frequency" do
  	expect(StandardRecord).to receive(:netsuite_poll)

  	StandardRecord.netsuite_sync_options[:frequency] = 5.minutes
  	timestamp = NetSuiteRails::PollTimestamp.for_class(StandardRecord)
  	timestamp.value = DateTime.now - 6.minutes
  	timestamp.save!

  	NetSuiteRails::PollTrigger.sync list_models: []
  end
end