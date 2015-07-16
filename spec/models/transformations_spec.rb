require 'spec_helper'

describe NetSuiteRails::Transformations do
  before(:each) do
    NetSuiteRails::Configuration.netsuite_instance_time_zone_offset -6
    # assume daylight savings time to make the tests less brittle
    allow_any_instance_of(ActiveSupport::TimeWithZone).to receive(:dst?).and_return(true)
    # TODO set local timezone
    ENV['TZ'] = 'EST'
    Time.zone = ActiveSupport::TimeZone[-5]
  end

  it 'handles very long phone numbers' do
    long_phone_number = '+1 (549)-880-4834 ext. 51077'

    expect(NetSuiteRails::Transformations.phone(long_phone_number)).to eq('5498804834x51077')

    weird_long_phone_number = '12933901964x89914'
    expect(NetSuiteRails::Transformations.phone(weird_long_phone_number)).to eq('2933901964x89914')
  end

  it "translates local date into NS datetime on push" do
    # dates in NS are really datetimes on the backend
    local_date = Date.parse("Sat, 01 Aug 2015")

    ns_date = DateTime.parse("Sat, 01 Aug 2015 00:00:00 -0500")
    expect(NetSuiteRails::Transformations.date(local_date, :push)).to eq(ns_date)
  end

  it "translates local datetime into NS datetime on push" do
    local_date = DateTime.parse('Fri May 29 11:52:47 EDT 2015')

    transformed_date = NetSuiteRails::Transformations.datetime(local_date, :push)
    expect(transformed_date.to_s).to eq('2015-05-29T12:52:47-05:00')
  end
end
