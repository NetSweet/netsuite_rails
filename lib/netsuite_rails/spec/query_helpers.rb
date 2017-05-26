module NetSuiteRails
  module Spec
    module QueryHelpers

      def self.included(base)
        base.before { netsuite_timestamp(DateTime.now) }
      end

      def netsuite_timestamp(stamp = nil)
        if stamp.nil?
          @netsuite_timestamp ||= (Time.now - (60 * 2)).to_datetime
        else
          @netsuite_timestamp = stamp
        end
      end

      def get_last_netsuite_object(record)
        # TODO support passing custom record ref

        if record.is_a?(Class)
          record_class = record
          is_custom_record = false
        else
          record_class = record.netsuite_record_class
          is_custom_record = record.netsuite_custom_record?
        end

        search = record_class.search({
          criteria: {
            basic:
            (
            if is_custom_record
              [
                {
                  field: 'recType',
                  operator: 'is',
                  value: NetSuite::Records::CustomRecordRef.new(internal_id: record.class.netsuite_custom_record_type_id)
                },
                {
                  field: 'lastModified',
                  operator: 'after',
                  value: netsuite_timestamp
                }
              ]
            else
              [
                {
                  field: 'lastModifiedDate',
                  operator: 'after',
                  value: netsuite_timestamp
                }
              ]
            end +

            if [ NetSuite::Records::SalesOrder, NetSuite::Records::ItemFulfillment, NetSuite::Records::Invoice ].include?(record_class)
              [
                {
                  field: 'type',
                  operator: 'anyOf',
                  value: [ '_' + record_class.name.demodulize.lower_camelcase ]
                }
              ]
            else
              []
            end
            )
          }
        })

        return nil if search.results.blank?

        if is_custom_record
          NetSuite::Utilities.backoff { NetSuite::Records::CustomRecord.get(
            internal_id: search.results.first.internal_id.to_i,
            type_id: record.class.netsuite_custom_record_type_id
          ) }
        else
          NetSuite::Utilities.backoff { record_class.get(search.results.first.internal_id.to_i) }
        end
      end

      # convenience method for inspecting objects in a live IRB session
      def netsuite_url(object)
        `open "#{NetSuiteRails::UrlHelper.netsuite_url(object)}"`
      end

    end
  end
end

RSpec.configure do |config|
  config.include NetSuiteRails::Spec::QueryHelpers
end
