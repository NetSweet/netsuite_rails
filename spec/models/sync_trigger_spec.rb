require 'spec_helper'

describe NetSuiteRails::SyncTrigger do
  include ExampleModels
  
  before do
    allow(NetSuiteRails::RecordSync::PushManager).to receive(:push_add)
    allow(NetSuiteRails::RecordSync::PushManager).to receive(:push_update)
  end

  context 'push' do
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

    it "should push the modified attributes to the model" do
      s = StandardRecord.new netsuite_id: 123
      allow(s).to receive(:netsuite_pull)
      s.save!

      # delayed_job isn't included in this gem; hack it into the current record instance
      s.instance_eval { def delay; self; end }
      allow(s).to receive(:delay).and_return(s)

      NetSuiteRails::Configuration.netsuite_sync_mode :async

      s.phone = Faker::PhoneNumber.phone_number
      s.save!

      NetSuiteRails::Configuration.netsuite_sync_mode :sync

      expect(s).to have_received(:delay)
      expect(NetSuiteRails::RecordSync::PushManager).to have_received(:push_update).with(anything, anything, {:modified_fields=>{:phone=> :phone}})
    end
  end

  context 'pull' do
    it 'should pull down a new record with a NS ID set on save' do
      s = StandardRecord.new netsuite_id: 123
      allow(s).to receive(:netsuite_pull_record).and_return(NetSuite::Records::Customer.new(phone: '1231231234'))
      allow(s).to receive(:netsuite_extract_from_record)

      s.save!

      expect(NetSuiteRails::RecordSync::PushManager).to_not have_received(:push_add)
      expect(NetSuiteRails::RecordSync::PushManager).to_not have_received(:push_update)
      expect(s).to have_received(:netsuite_extract_from_record)
    end
  end

end