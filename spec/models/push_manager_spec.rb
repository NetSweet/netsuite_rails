require 'spec_helper'

describe NetSuiteRails::RecordSync::PushManager do

  it "should push new record when saved" do
    define_model :standard_record, phone: :string, netsuite_id: :integer do
      include NetSuiteRails::RecordSync
      netsuite_record_class NetSuite::Records::Customer
      netsuite_sync :read_write
      netsuite_field_map({
        :phone => :phone
      })

    end

    allow(subject.class).to receive(:push_add).and_return(true)

    s = StandardRecord.new
    s.phone = Faker::PhoneNumber.phone_number
    s.save!

    expect(subject.class).to have_received(:push_add)
    expect(subject.class).to_not have_received(:push_update)
  end

end