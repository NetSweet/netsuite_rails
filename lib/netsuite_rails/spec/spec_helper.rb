require 'netsuite'

module NetSuiteRails::TestHelpers

  def self.included(base)
    base.before { netsuite_timestamp(DateTime.now) }
  end

  def netsuite_timestamp(stamp = nil)
    if stamp.nil?
      @netsuite_timestamp ||= (Time.now - (60 * 2)).to_datetime
    else
      @netsuite_timestamp ||= stamp
    end
  end

  def get_last_netsuite_object(record)
    search = record.netsuite_record_class.search({
      criteria: {
        basic:
        if record.netsuite_custom_record?
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
        end
      }
    })

    if record.netsuite_custom_record?
      NetSuite::Records::CustomRecord.get(
        internal_id: search.results.first.internal_id.to_i,
        type_id: record.class.netsuite_custom_record_type_id
      )
    else
      record.netsuite_record_class.get(search.results.first.internal_id.to_i)
    end
  end

end