require 'spec_helper'

# TODO https://github.com/NetSweet/netsuite_rails/issues/16
# there are still some unresolved issues with NS datetime/date conversions
# the tests + implementation may still not be correct.

describe NetSuiteRails::Transformations do
  before do
    ENV['TZ'] = 'EST'
    Rails.configuration.time_zone = 'Eastern Time (US & Canada)'
    Time.zone = ActiveSupport::TimeZone[-5]

    NetSuiteRails::Configuration.netsuite_instance_time_zone_offset -6
  end

  it 'nils out short phone numbers' do
    short_phone_number = '  301908  '

    expect(NetSuiteRails::Transformations.phone(short_phone_number)).to be_nil
  end

  it 'handles very long phone numbers' do
    long_phone_number = '+1 (549)-880-4834 ext. 51077'

    expect(NetSuiteRails::Transformations.phone(long_phone_number)).to eq('5498804834x51077')

    weird_long_phone_number = '12933901964x89914'
    expect(NetSuiteRails::Transformations.phone(weird_long_phone_number)).to eq('2933901964x89914')
  end

  it "translates local date into NS date" do
    # from what I can tell, NetSuite stores dates with a -07:00 offset
    # and subtracts (PST - NS instance timezone) hours from the stored datetime

    local_date = DateTime.parse("2015-07-24T00:00:00.000-05:00")
    transformed_date = NetSuiteRails::Transformations.date(local_date, :push)
    expect(transformed_date.to_s).to eq("2015-07-24T12:00:00-07:00")
  end

  it "translates local datetime into NS datetime" do
    # TODO set local timezone
    local_date = DateTime.parse('Fri May 29 11:52:47 EDT 2015')
    NetSuiteRails::Configuration.netsuite_instance_time_zone_offset -6

    transformed_date = NetSuiteRails::Transformations.datetime(local_date, :push)
    # TODO this will break as PDT daylight savings is switched; need to freeze the system time for testing
    expect(transformed_date.to_s).to eq('1970-01-01T09:52:47-08:00')
  end

  it 'transforms a datetime value pulled from netsuite correctly' do
    # assuming that the date in CST is displayed as 5am
    # in the rails backend we want to store the date as EST with a CST hour

    netsuite_time = DateTime.parse('1970-01-01T03:00:00.000-08:00')
    transformed_netsuite_time = NetSuiteRails::Transformations.datetime(netsuite_time, :pull)
    expect(transformed_netsuite_time.to_s).to eq('1970-01-01T05:00:00-05:00')
  end

  it 'transforms a invalid email' do
    netsuite_email = ' hey@example.com. '
    transformed_netsuite_email = NetSuiteRails::Transformations.email(netsuite_email, :push)
    expect(transformed_netsuite_email.to_s).to eq('hey@example.com')

    netsuite_email = ' example+second@example.family. '
    transformed_netsuite_email = NetSuiteRails::Transformations.email(netsuite_email, :push)
    expect(transformed_netsuite_email.to_s).to eq('example+second@example.family')

    netsuite_email = ' example,second@example.com '
    transformed_netsuite_email = NetSuiteRails::Transformations.email(netsuite_email, :push)
    expect(transformed_netsuite_email.to_s).to eq('examplesecond@example.com')

    netsuite_email = 'boom.@gmail.com'
    transformed_netsuite_email = NetSuiteRails::Transformations.email(netsuite_email, :push)
    expect(transformed_netsuite_email.to_s).to eq('boom@gmail.com')

    netsuite_email = 'boom&boo@gmail.com'
    transformed_netsuite_email = NetSuiteRails::Transformations.email(netsuite_email, :push)
    expect(transformed_netsuite_email.to_s).to eq('boom&boo@gmail.com')

    netsuite_email = 'boom@gmail&hotmail.com'
    transformed_netsuite_email = NetSuiteRails::Transformations.email(netsuite_email, :push)
    expect(transformed_netsuite_email.to_s).to eq('boom@gmailhotmail.com')

    netsuite_email = 'first@example.com,second@example.com,third@example.com,fourth@example.com'
    transformed_netsuite_email = NetSuiteRails::Transformations.email(netsuite_email, :push)
    expect(transformed_netsuite_email.to_s).to eq('firstexample.comsecondexample.comthirdexample.comfourth@example.com')

    netsuite_email = "some\\@example.com"
    transformed_netsuite_email = NetSuiteRails::Transformations.email(netsuite_email, :push)
    expect(transformed_netsuite_email.to_s).to eq('some@example.com')
  end

  it 'truncates gift card code' do
    code = Faker::Lorem.characters(10)
    expect(NetSuiteRails::Transformations.gift_card_code(code, :push).size).to eq(9)
  end
end
