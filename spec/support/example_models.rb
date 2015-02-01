module ExampleModels

  def self.included(example_group)
    example_group.class_eval do
      before do

        define_model :standard_record, phone: :string, netsuite_id: :integer do
          include NetSuiteRails::RecordSync

          netsuite_record_class NetSuite::Records::Customer
          netsuite_sync :read_write
          netsuite_field_map({
            :phone => :phone
          })
        end

        define_model :custom_record, netsuite_id: :integer, value: :string do
          include NetSuiteRails::RecordSync

          netsuite_record_class NetSuite::Records::CustomRecord, 123
          netsuite_sync :read_write
          netsuite_field_map({
            :custom_field_list => {
              :value => :custrecord_another_value
            }
          })
        end

        define_model :standard_list, netsuite_id: :integer, value: :string do
          include NetSuiteRails::ListSync
          netsuite_list_id 86
        end
      end

      after do
        NetSuiteRails::PollTrigger.instance_variable_set('@record_models', [])
        NetSuiteRails::PollTrigger.instance_variable_set('@list_models', [])
      end

    end
  end
end
