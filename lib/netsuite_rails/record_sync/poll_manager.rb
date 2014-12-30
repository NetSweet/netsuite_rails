module NetSuiteRails
  module RecordSync
    module PollManager
      extend self

      def update_local_records(klass, opts = {})
        klass.select([:netsuite_id, :id]).find_in_batches(batch_size: NetSuiteRails::Configuration.polling_page_size) do |local_batch|
          netsuite_batch = if klass.netsuite_custom_record?
            NetSuite::Records::CustomRecord.get_list(
              list: local_batch.map(&:netsuite_id),
              type_id: klass.netsuite_custom_record_type_id,
              allow_incomplete: true
            )
          else
            klass.netsuite_record_class.get_list(
              list: local_batch.map(&:netsuite_id),
              allow_incomplete: true
            )
          end

          unless netsuite_batch
            binding.pry
          end

          netsuite_batch.each do |netsuite_record|
            self.process_search_result_item(klass, opts, netsuite_record)
          end
        end
      end

      def poll(klass, opts = {})
        opts = {
          import_all: false,
          page_size: NetSuiteRails::Configuration.polling_page_size,
        }.merge(opts)

        opts[:netsuite_record_class] ||= klass.netsuite_record_class
        opts[:saved_search_id] ||= klass.netsuite_sync_options[:saved_search_id]

        search = opts[:netsuite_record_class].search(
          poll_criteria(klass, opts).merge({
            preferences: {
              body_fields_only: false,
              page_size: opts[:page_size]
            }
          })
        )

        # TODO more robust error reporting
        unless search
          raise 'error running netsuite sync'
        end

        process_search_results(klass, opts, search)
      end

      def poll_criteria(klass, opts)
        search_criteria = {
          criteria: {
            basic: poll_basic_criteria(klass, opts)
          }
        }

        if opts[:saved_search_id]
          search_criteria[:criteria][:saved] = opts[:saved_search_id]
        end

        if needs_get_list?(opts)
          search_criteria[:columns] = {
            'listRel:basic' => [
              'platformCommon:internalId/' => {},
            ],
          }
        end

        search_criteria
      end

      def poll_basic_criteria(klass, opts)
        opts = {
          criteria: [],
          # last_poll: DateTime
        }.merge(opts)

        # allow custom criteria to be passed directly to the sync call
        criteria = opts[:criteria] || []

        # allow custom criteria from the model level
        criteria += klass.netsuite_sync_options[:criteria] || []

        if opts[:netsuite_record_class] == NetSuite::Records::CustomRecord
          opts[:netsuite_custom_record_type_id] ||= klass.netsuite_custom_record_type_id
          
          criteria << {
            field: 'recType',
            operator: 'is',
            value: NetSuite::Records::CustomRecordRef.new(internal_id: opts[:netsuite_custom_record_type_id])
          }
        end

        unless opts[:import_all]
          criteria << {
            # CustomRecordSearchBasic uses lastModified instead of the standard lastModifiedDate
            field: (klass.netsuite_custom_record?) ? 'lastModified' : 'lastModifiedDate',
            operator: 'after',
            value: opts[:last_poll]
          }
        end

        criteria
      end

      def process_search_results(klass, opts, search)
        opts = {
          skip_existing: false,
          full_record_data: -1,
        }.merge(opts)

        Rails.logger.info "NetSuite: Processing #{search.total_records} over #{search.total_pages} pages"

        # TODO need to improve the conditional here to match the get_list call conditional belo
        if opts[:import_all] && opts[:skip_existing]
          synced_netsuite_list = klass.pluck(:netsuite_id)
        end
        
        search.results_in_batches do |batch|
          # a saved search is processed as a advanced search; advanced search often does not allow you to retrieve
          # all of the fields (ex: addressbooklist on customer) that a normal search does
          # the only way to get those fields is to pull down the full record again using getAll

          if needs_get_list?(opts)
            filtered_netsuite_id_list = batch.map(&:internal_id).map(&:to_i)

            if opts[:skip_existing] == true
              filtered_netsuite_id_list.reject! { |netsuite_id| synced_netsuite_list.include?(netsuite_id) }
            end

            if filtered_netsuite_id_list.present?
              opts[:netsuite_record_class].get_list(list: filtered_netsuite_id_list)
            else
              []
            end
          else
            batch
          end.each do |netsuite_record|
            self.process_search_result_item(klass, opts, netsuite_record)
          end
        end
      end

      def process_search_result_item(klass, opts, netsuite_record)
        local_record = klass.where(netsuite_id: netsuite_record.internal_id).first_or_initialize

        # when importing lots of records during an import_all skipping imported records is important
        return if opts[:skip_existing] == true && !local_record.new_record?

        local_record.netsuite_extract_from_record(netsuite_record)

        # TODO optionally throw fatal errors; we want to skip fatal errors on intial import

        unless local_record.save
          Rails.logger.error "NetSuite: Error pulling record #{klass} NS ID #{netsuite_record.internal_id} #{local_record.errors.full_messages}"
        end
      end

      def needs_get_list?(opts)
        (opts[:saved_search_id].present? && opts[:full_record_data] != false) || opts[:full_record_data] == true
      end

      # TODO this should remain in the pull manager

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