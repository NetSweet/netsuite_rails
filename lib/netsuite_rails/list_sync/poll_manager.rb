module NetSuiteRails
  module ListSync
    module PollManager
      extend self

      def poll(klass, opts = {})
        custom_list = NetSuite::Utilities.backoff { NetSuite::Records::CustomList.get(klass.netsuite_list_id) }

        process_results(klass, opts, custom_list.custom_value_list.custom_value)
      end

      def process_results(klass, opts, list)
        list.each do |custom_value|
          local_record = klass.where(netsuite_id: custom_value.attributes[:value_id]).first_or_initialize

          if local_record.respond_to?(:value=)
            local_record.value = custom_value.attributes[:value]
          end

          if local_record.respond_to?(:inactive=)
            local_record.inactive = custom_value.attributes[:is_inactive]
          end

          local_record.save!
        end
      end

    end
  end
end
