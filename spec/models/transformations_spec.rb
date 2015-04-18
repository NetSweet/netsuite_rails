require 'spec_helper'

describe NetSuiteRails::Transformations do
  it 'handles very long phone numbers' do
    long_phone_number = '+1 (549)-880-4834 ext. 51077'
    
    expect(NetSuiteRails::Transformations.phone(long_phone_number)).to eq('5498804834x51077')

    weird_long_phone_number = '12933901964x89914'
    expect(NetSuiteRails::Transformations.phone(weird_long_phone_number)).to eq('2933901964 x89914')
  end
end