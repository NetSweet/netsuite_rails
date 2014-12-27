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

      end
    end
  end
end
