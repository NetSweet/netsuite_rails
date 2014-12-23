require 'spec_helper'

describe NetSuiteRails::SyncTrigger do

  before do
    define_model :standard_record, phone: :string, netsuite_id: :integer do
      include NetSuiteRails::RecordSync

      netsuite_record_class NetSuite::Records::Customer
      netsuite_sync :read_write
      netsuite_field_map({
        :phone => :phone
      })
    end

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

end