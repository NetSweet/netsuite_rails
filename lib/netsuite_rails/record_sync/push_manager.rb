module NetSuiteRails
  module RecordSync

    class PushManager
      class << self

        def push(local_record, opts = {})
          # TODO check to see if anything is changed before moving forward
          # if changes_keys.blank? && local_record.netsuite_manual_fields

          if opts[:modified_fields]
            # if Array, we need to convert info fields hash based on the record definition
            if opts[:modified_fields].is_a?(Array)
              opts[:modified_fields] = all_netsuite_fields(local_record).select { |k,v| opts[:modified_fields].include?(k) }
            end
          else
            opts[:modified_fields] = modified_local_fields(local_record)
          end

          netsuite_record = build_netsuite_record(local_record, opts)

          local_record.netsuite_execute_callbacks(local_record.class.before_netsuite_push, netsuite_record)

          if opts[:push_method] == :upsert || local_record.new_netsuite_record?
            push_add(local_record, netsuite_record, opts)
          else
            push_update(local_record, netsuite_record, opts)
          end

          # :aggressive is for custom fields which are based on input – need pull updated values after
          # the push to netsuite to retrieve the calculated values

          if local_record.netsuite_sync == :aggressive
            local_record.netsuite_pull
          end

          local_record.netsuite_execute_callbacks(local_record.class.after_netsuite_push, netsuite_record)

          true
        end

        def push_add(local_record, netsuite_record, opts = {})
          if netsuite_record.send(opts[:push_method] || :add)
            if is_active_record_model?(local_record)
              # update_column to avoid triggering another save
              local_record.update_column(:netsuite_id, netsuite_record.internal_id)
            else
              netsuite_record.internal_id
            end
          else
            raise "NetSuite: error creating record #{netsuite_record.errors}"
          end
        end

        def push_update(local_record, netsuite_record, opts = {})
          # build change hash to limit the number of fields pushed to NS on change
          # NS could have logic which could change field functionality depending on
          # input data; it's safest to limit the number of field changes pushed to NS

          custom_field_list = local_record.netsuite_field_map[:custom_field_list] || {}
          modified_fields_list = opts[:modified_fields]

          update_list = {}

          modified_fields_list.each do |local_field, netsuite_field|
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

        def build_netsuite_record(local_record, opts = {})
          netsuite_record = build_netsuite_record_reference(local_record, opts)

          all_field_list = opts[:modified_fields]
          custom_field_list = local_record.netsuite_field_map[:custom_field_list] || {}
          field_hints = local_record.netsuite_field_hints

          reflections = relationship_attributes_list(local_record)

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

        def build_netsuite_record_reference(local_record, opts = {})
          # must set internal_id for records on new; will be set to nil if new record

          init_hash = if opts[:use_external_id]
            { external_id: local_record.netsuite_external_id }
          else
            { internal_id: local_record.netsuite_id }
          end

          netsuite_record = local_record.netsuite_record_class.new(init_hash)

          if local_record.netsuite_custom_record?
            netsuite_record.rec_type = NetSuite::Records::CustomRecord.new(internal_id: local_record.class.netsuite_custom_record_type_id)
          end

          netsuite_record
        end

        def modified_local_fields(local_record)
          synced_netsuite_fields = all_netsuite_fields(local_record)

          changed_keys = if is_active_record_model?(local_record)
            changed_attributes(local_record)
          else
            local_record.changed_attributes
          end

          # filter out unchanged keys when updating record
          unless local_record.new_netsuite_record?
            synced_netsuite_fields.select! { |k,v| changed_keys.include?(k) }
          end

          synced_netsuite_fields
        end

        def all_netsuite_fields(local_record)
          custom_netsuite_field_list = local_record.netsuite_field_map[:custom_field_list] || {}
          standard_netsuite_field_list = local_record.netsuite_field_map.except(:custom_field_list) || {}

          custom_netsuite_field_list.merge(standard_netsuite_field_list)
        end

        def changed_attributes(local_record)
          # otherwise filter only by attributes that have been changed
          # limiting the delta sent to NS will reduce hitting edge cases

          # TODO think about has_many / join table changes

          reflections = relationship_attributes_list(local_record)

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

          serialized_attrs = if NetSuiteRails.rails4?
            local_record.class.serialized_attributes
          else
            local_record.serialized_attributes
          end

          # changes_attributes does not track serialized attributes, although it does track the storage key
          # if a serialized attribute storage key is dirty assume that all keys in the hash are dirty as well
          
          changed_attributes_keys += serialized_attrs.keys.map do |k|
            local_record.send(k.to_sym).keys.map(&:to_s)
          end.flatten

          # convert relationship symbols from :object_id to :object
          changed_attributes_keys.map do |k|
            association_field_key_mapping[k.to_sym] || k.to_sym
          end
        end

        def relationship_attributes_list(local_record)
          if is_active_record_model?(local_record)
            if NetSuiteRails.rails4?
              local_record.class.reflections
            else
              local_record.reflections
            end
          else
            local_record.respond_to?(:reflections) ? local_record.reflections : {}
          end
        end

        def is_active_record_model?(local_record)
          local_record.class.ancestors.include?(ActiveRecord::Base)
        end

      end
    end

  end
end