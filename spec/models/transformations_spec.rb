require 'spec_helper'

describe NetSuiteRails::Transformations do
  it 'handles very long phone numbers' do
    long_phone_number = '+1 (549)-880-4834 ext. 51077'

    expect(NetSuiteRails::Transformations.phone(long_phone_number)).to eq('5498804834x51077')

    weird_long_phone_number = '12933901964x89914'
    expect(NetSuiteRails::Transformations.phone(weird_long_phone_number)).to eq('2933901964x89914')
  end

  it "translates local date into NS date" do

  end

  it "translates local datetime into NS datetime" do
    ENV['TZ'] = 'EST'
    Time.zone = ActiveSupport::TimeZone[-5]

    # TODO set local timezone
    local_date = DateTime.parse('Fri May 29 11:52:47 EDT 2015')
    NetSuiteRails::Configuration.netsuite_instance_time_zone_offset -6

    transformed_date = NetSuiteRails::Transformations.datetime(local_date)
    # TODO this will break as PDT daylight savings is switched; need to freeze the system time for testing
    expect(transformed_date.to_s).to eq('2015-05-29T08:52:47-08:00')
  end
end
