module NetSuiteRails
  module ListSync

    def self.included(klass)
      klass.send(:extend, ClassMethods)

      PollManager.attach(klass)
    end

    module ClassMethods
      def netsuite_list_id(internal_id)
        @netsuite_list_id = internal_id
      end

      def netsuite_poll
        custom_list = NetSuite::Records::CustomList.get(@netsuite_list_id)
        custom_list.custom_value_list.custom_value.each do |custom_value|
          local_record = self.find_or_initialize_by(netsuite_id: custom_value.attributes[:value_id])
          local_record.value = custom_value.attributes[:value] if local_record.respond_to?(:value=)
          local_record.inactive = custom_value.attributes[:is_inactive] if local_record.respond_to?(:inactive=)
          local_record.save!
        end
      end
    end

  end
end
