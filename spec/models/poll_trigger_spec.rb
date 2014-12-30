require 'spec_helper'

describe NetSuiteRails::PollTrigger do
  include ExampleModels

  it "should properly sync for the first time" do
  	allow(StandardRecord).to receive(:netsuite_poll).with(hash_including(:import_all => true))

  	NetSuiteRails::PollTrigger.sync list_models: []

  	expect(StandardRecord).to have_received(:netsuite_poll)
  end

  it "should trigger syncing when the time has passed is greater than frequency" do
  	allow(StandardRecord).to receive(:netsuite_poll)

  	StandardRecord.netsuite_sync_options[:frequency] = 5.minutes
  	timestamp = NetSuiteRails::PollTimestamp.for_class(StandardRecord)
  	timestamp.value = DateTime.now - 7.minutes
  	timestamp.save!

  	NetSuiteRails::PollTrigger.sync list_models: []

  	expect(StandardRecord).to have_received(:netsuite_poll)
  end
end