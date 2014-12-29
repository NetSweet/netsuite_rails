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

        define_model :standard_list, netsuite_id: :integer, value: :string do
          include NetSuiteRails::ListSync
          netsuite_list_id 86
        end

      end
    end
  end
end
