require 'spec_helper'

# TODO https://github.com/NetSweet/netsuite_rails/issues/16
# there are still some unresolved issues with NS datetime/date conversions
# the tests + implementation may still not be correct.

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

    transformed_date = NetSuiteRails::Transformations.datetime(local_date, :push)
    # TODO this will break as PDT daylight savings is switched; need to freeze the system time for testing
    expect(transformed_date.to_s).to eq('1970-01-01T09:52:47-08:00')
  end

  it 'transforms a datetime value pulled from netsuite correctly' do
    ENV['TZ'] = 'EST'
    Rails.configuration.time_zone = 'Eastern Time (US & Canada)'
    Time.zone = ActiveSupport::TimeZone[-5]

    NetSuiteRails::Configuration.netsuite_instance_time_zone_offset -6

    # assuming that the date in CST is displayed as 5am
    # in the rails backend we want to store the date as EST with a CST hour

    netsuite_time = DateTime.parse('1970-01-01T03:00:00.000-08:00')
    transformed_netsuite_time = NetSuiteRails::Transformations.datetime(netsuite_time, :pull)
    expect(transformed_netsuite_time.to_s).to eq('1970-01-01T05:00:00-05:00')
  end
end
