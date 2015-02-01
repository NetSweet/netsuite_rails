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
end
