module NetSuiteRails
  module RecordSync
    module PullManager
      extend self

      # TODO pull relevant methods out of poll manager and into this class

      def extract_custom_field_value(custom_field_value)
        if custom_field_value.present? && custom_field_value.is_a?(Hash) && custom_field_value.has_key?(:name)
          custom_field_value = custom_field_value[:name]
        end

        if custom_field_value.present? && custom_field_value.is_a?(NetSuite::Records::CustomRecordRef)
          custom_field_value = custom_field_value.attributes[:name]
        end

        custom_field_value
      end

    end
  end
end
