require 'spec_helper'

describe NetSuiteRails::PollTrigger do
  include ExampleModels

  it "should properly sync for the first time" do
  	allow(NetSuiteRails::RecordSync::PollManager).to receive(:poll)

  	NetSuiteRails::PollTrigger.sync list_models: [], record_models: [ StandardRecord ]

  	expect(NetSuiteRails::RecordSync::PollManager).to have_received(:poll)
  end

  it "should trigger syncing is triggered from the model when time passed is greater than frequency" do
  	allow(StandardRecord).to receive(:netsuite_poll)
    allow(StandardRecord.netsuite_record_class).to receive(:search).and_return(OpenStruct.new(results: []))

  	StandardRecord.netsuite_sync_options[:frequency] = 5.minutes

  	timestamp = NetSuiteRails::PollTimestamp.for_class(StandardRecord)
  	timestamp.value = DateTime.now - 6.minutes
  	timestamp.save!

  	NetSuiteRails::PollTrigger.sync list_models: [], record_models: [ StandardRecord ]

  	expect(StandardRecord).to have_received(:netsuite_poll)
  end

  it 'should not change the poll timestamp when sync does not occur' do
    allow(StandardRecord).to receive(:netsuite_poll)

    StandardRecord.netsuite_sync_options[:frequency] = 5.minutes

    last_timestamp = DateTime.now - 3.minutes

    timestamp = NetSuiteRails::PollTimestamp.for_class(StandardRecord)
    timestamp.value = last_timestamp
    timestamp.save!

    NetSuiteRails::PollTrigger.sync list_models: [], record_models: [ StandardRecord ]

    expect(StandardRecord).to_not have_received(:netsuite_poll)
    timestamp = NetSuiteRails::PollTimestamp.find(timestamp.id)
    expect(timestamp.value).to eq(last_timestamp)
  end
end