require 'spec_helper'

describe NetSuiteRails::SyncTrigger do
  include ExampleModels
  
  before do
    allow(NetSuiteRails::RecordSync::PushManager).to receive(:push_add)
    allow(NetSuiteRails::RecordSync::PushManager).to receive(:push_update)
  end

  it "should push new record when saved" do
    s = StandardRecord.new
    s.phone = Faker::PhoneNumber.phone_number
    s.save!

    expect(NetSuiteRails::RecordSync::PushManager).to have_received(:push_add)
    expect(NetSuiteRails::RecordSync::PushManager).to_not have_received(:push_update)
  end

  it "should not push update on a pull record" do
    s = StandardRecord.new netsuite_id: 123
    allow(s).to receive(:netsuite_pull)
    s.save!

    expect(s).to have_received(:netsuite_pull)
    expect(NetSuiteRails::RecordSync::PushManager).to_not have_received(:push_add)
    expect(NetSuiteRails::RecordSync::PushManager).to_not have_received(:push_update)
  end

  it "should push an update on an existing record" do
    s = StandardRecord.new netsuite_id: 123
    allow(s).to receive(:netsuite_pull)
    s.save!

    s.phone = Faker::PhoneNumber.phone_number
    s.save!

    expect(NetSuiteRails::RecordSync::PushManager).to_not have_received(:push_add)
    expect(NetSuiteRails::RecordSync::PushManager).to have_received(:push_update)
  end

  it "should push the modified attributes to the model" do
    s = StandardRecord.new netsuite_id: 123
    allow(s).to receive(:netsuite_pull)
    s.save!

    delayer = Object.new
    delayer.instance_eval { def netsuite_push(opts); end }
    expect(delayer).to receive(:netsuite_push).with({:modified_fields=>[:phone]})

    s.instance_eval do
      def delay
        delayer
      end
    end

    NetSuiteRails::Configuration.netsuite_sync_mode :async
    allow(s).to receive(:delay).and_return(delayer)

    s.phone = Faker::PhoneNumber.phone_number
    s.save!

    NetSuiteRails::Configuration.netsuite_sync_mode :sync
  end

end