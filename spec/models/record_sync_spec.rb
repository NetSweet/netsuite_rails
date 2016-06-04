require 'spec_helper'

describe NetSuiteRails::RecordSync do
  include ExampleModels

  context 'custom records' do
    it "should properly pull the NS rep" do
      allow(NetSuite::Records::CustomRecord).to receive(:get).with(hash_including(:internal_id => 234, type_id: 123))

      custom_record = CustomRecord.new netsuite_id: 234
      custom_record.netsuite_pull_record

      expect(NetSuite::Records::CustomRecord).to have_received(:get)
    end
  end

  it 'properly extracts common record types' do
    fake_customer_data = {
      :is_inactive => false,
      :phone => "123 456 7891",
      :company_name => "Great Company",
      :email => nil
    }

    expect(NetSuite::Records::Customer).to receive(:get)
      .and_return(NetSuite::Records::Customer.new(fake_customer_data))

    standard_record = StandardRecord.new netsuite_id: 123
    standard_record.netsuite_pull

    expect(standard_record.is_deleted).to eq(false)
    expect(standard_record.phone).to eq(fake_customer_data[:phone])
    expect(standard_record.company).to eq(fake_customer_data[:company_name])
    expect(standard_record.email).to eq(fake_customer_data[:email])
  end
end
