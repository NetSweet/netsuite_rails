require 'spec_helper'

describe NetSuiteRails::Transformations do
  it 'handles very long phone numbers' do
    long_phone_number = '+1 (549)-880-4834 ext. 51077'
    
    expect(NetSuiteRails::Transformations.phone(long_phone_number)).to eq('1 5498804834 x 51077')
  end
end