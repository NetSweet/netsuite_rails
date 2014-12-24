module NetSuiteRails
  module RecordSync

    class PushManager
      class << self

        def push(local_record, opts)
          # TODO check to see if anything is changed before moving forward
          # if changes_keys.blank? && local_record.netsuite_manual_fields

          netsuite_record = build_netsuite_record(local_record)

          local_record.netsuite_execute_callbacks(local_record.class.before_netsuite_push, netsuite_record)

          if !local_record.new_netsuite_record?
            push_update(local_record, netsuite_record)
          else
            push_add(local_record, netsuite_record)
          end

          # :aggressive is for custom fields which are based on input – need pull updated values after
          # the push to netsuite to retrieve the calculated values

          if local_record.netsuite_sync == :aggressive
            local_record.netsuite_pull
          end

          local_record.netsuite_execute_callbacks(local_record.class.after_netsuite_push, netsuite_record)

          true
        end

        def push_add(local_record, netsuite_record)
          if netsuite_record.add
            # update_column to avoid triggering another save
            local_record.update_column(:netsuite_id, netsuite_record.internal_id)
          else
            # TODO use NS error class
            raise "NetSuite: error creating record #{netsuite_record.errors}"
          end
        end

        def push_update(local_record, netsuite_record)
          # build change hash to limit the number of fields pushed to NS on change
          # NS could have logic which could change field functionality depending on
          # input data; it's safest to limit the number of field changes pushed to NS

          custom_field_list = local_record.netsuite_field_map[:custom_field_list] || {}
          all_field_list = eligible_local_fields(local_record)

          update_list = {}

          all_field_list.each do |local_field, netsuite_field|
            if custom_field_list.keys.include?(local_field)
              # if custom field has changed, mark and copy over customFieldList later
              update_list[:custom_field_list] = true
            else
              update_list[netsuite_field] = netsuite_record.send(netsuite_field)
            end
          end

          # manual field list is for fields manually defined on the NS record
          # outside the context of ActiveRecord (e.g. in a before_netsuite_push)

          (local_record.netsuite_manual_fields || []).each do |netsuite_field|
            if netsuite_field == :custom_field_list
              update_list[:custom_field_list] = true
            else
              update_list[netsuite_field] = netsuite_record.send(netsuite_field)
            end
          end

          if update_list[:custom_field_list]
            update_list[:custom_field_list] = netsuite_record.custom_field_list
          end

          if local_record.netsuite_custom_record?
            update_list[:rec_type] = netsuite_record.rec_type
          end

          # TODO consider using upsert here

          if netsuite_record.update(update_list)
            true
          else
            raise "NetSuite: error updating record #{netsuite_record.errors}"
          end
        end

        def build_netsuite_record(local_record)
          netsuite_record = build_netsuite_record_reference(local_record)

          # TODO need to normalize datetime fields

          all_field_list = eligible_local_fields(local_record)
          custom_field_list = local_record.netsuite_field_map[:custom_field_list] || {}
          field_hints = local_record.netsuite_field_hints

          reflections = if NetSuiteRails.rails4?
            local_record.class.reflections
          else
            local_record.reflections
          end

          all_field_list.each do |local_field, netsuite_field|
            # allow Procs as field mapping in the record definition for custom mapping
            if netsuite_field.is_a?(Proc)
              netsuite_field.call(local_record, netsuite_record, :push)
              next
            end

            # TODO pretty sure this will break if we are dealing with has_many 

            netsuite_field_value = if reflections.has_key?(local_field)
              if (remote_internal_id = local_record.send(local_field).try(:netsuite_id)).present?
                { internal_id: remote_internal_id }
              else
                nil
              end
            else
              local_record.send(local_field)
            end

            if field_hints.has_key?(local_field) && netsuite_field_value.present?
              netsuite_field_value = NetSuiteRails::Transformations.transform(field_hints[local_field], netsuite_field_value)
            end

            # TODO should we skip setting nil values completely? What if we want to nil out fields on update?

            # be wary of API version issues: https://github.com/NetSweet/netsuite/issues/61

            if custom_field_list.keys.include?(local_field)
              netsuite_record.custom_field_list.send(:"#{netsuite_field}=", netsuite_field_value)
            else
              netsuite_record.send(:"#{netsuite_field}=", netsuite_field_value)
            end
          end

          netsuite_record
        end

        def build_netsuite_record_reference(local_record)
          # must set internal_id for records on new; will be set to nil if new record

          netsuite_record = local_record.netsuite_record_class.new(internal_id: local_record.netsuite_id)

          if local_record.netsuite_custom_record?
            netsuite_record.rec_type = NetSuite::Records::CustomRecord.new(internal_id: local_record.class.netsuite_custom_record_type_id)
          end

          netsuite_record
        end

        def eligible_local_fields(local_record)
          custom_field_list = local_record.netsuite_field_map[:custom_field_list] || {}
          all_field_list = local_record.netsuite_field_map.except(:custom_field_list) || {}

          all_field_list.merge!(custom_field_list)

          changed_keys = changed_attributes(local_record)

          # filter out unchanged keys when updating record
          unless local_record.new_netsuite_record?
            all_field_list.select! { |k,v| changed_keys.include?(k) }
          end

          all_field_list
        end

        def changed_attributes(local_record)
          # otherwise filter only by attributes that have been changed
          # limiting the delta sent to NS will reduce hitting edge cases

          # TODO think about has_many / join table changes

          reflections = if NetSuiteRails.rails4?
            local_record.class.reflections
          else
            local_record.reflections
          end

          association_field_key_mapping = reflections.values.reject(&:collection?).inject({}) do |h, a|
            begin
              h[a.association_foreign_key.to_sym] = a.name
            rescue Exception => e
              # occurs when `has_one through:` exists on a record but `through` is not a valid reference
              Rails.logger.error "NetSuite: error detecting foreign key #{a.name}"
            end

            h
          end

          changed_attributes_keys = local_record.changed_attributes.keys

          # TODO documentation about serialized values
          changed_attributes_keys += local_record.serialized_attributes.keys.map do |k|
            local_record.send(k.to_sym).keys.map(&:to_s)
          end.flatten

          # convert relationship symbols from :object_id to :object
          changed_attributes_keys.map do |k|
            association_field_key_mapping[k.to_sym] || k.to_sym
          end
        end


      end
    end

  end
end