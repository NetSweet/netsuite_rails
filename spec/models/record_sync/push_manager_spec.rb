describe NetSuiteRails::RecordSync::PushManager do
  include ExampleModels

  it 'should handle a modified field with a Proc instead of a netsuite field key' do
    record = StandardRecord.new netsuite_id: 234
    allow(record).to receive(:new_netsuite_record?).and_return(false)

    ns_record = record.netsuite_record_class.new

    NetSuiteRails::RecordSync::PushManager.push(record, { modified_fields: [ :company ] })
  end

  it 'should ignore modified fields if the record has not yet been pushed to NetSuite' do
    record = StandardRecord.new

    expect(NetSuiteRails::RecordSync::PushManager).to receive(:push_add).once
    expect(NetSuiteRails::RecordSync::PushManager).to receive(:build_netsuite_record).with(instance_of(StandardRecord), hash_including({
      :modified_fields => hash_including(:phone, :company)
    }))

    NetSuiteRails::RecordSync::PushManager.push(record, { modified_fields: [ :company ] })
  end

  context "AR" do
    xit "should look at the NS ID of a has_one relationship on the record sync model"

    xit "should properly determine the changed attributes"
  end

  context "not AR" do
    xit "should execute properly for a simple active model class"

  end

  context 'record building' do
    it "should properly handle custom records" do
      custom = CustomRecord.new netsuite_id: 234
      record = NetSuiteRails::RecordSync::PushManager.build_netsuite_record_reference(custom)

      expect(record.internal_id).to eq(234)
      expect(record.rec_type.internal_id).to eq(123)
    end

    it "should properly handle records using external ID" do
      local = ExternalIdRecord.new(netsuite_id: 123, phone: "234")
      record = NetSuiteRails::RecordSync::PushManager.build_netsuite_record_reference(local, { use_external_id: true })

      expect(record.external_id).to eq(local.netsuite_external_id)
    end
  end
end
