module NetSuiteRails
  module RecordSync

    def self.included(klass)
      klass.class_eval do
        class_attribute :netsuite_settings

        self.netsuite_settings = {
          before_netsuite_push: [],
          after_netsuite_push: [],
          after_netsuite_pull: [],

          netsuite_sync: :read,
          netsuite_field_map: {},
          netsuite_field_hints: {},
          netsuite_record_class: nil,
        }

        cattr_accessor :netsuite_custom_record_type_id
        cattr_accessor :netsuite_sync_options

        self.netsuite_sync_options = {}
      end

      klass.send(:extend, ClassMethods)
      klass.send(:include, InstanceMethods)

      SyncTrigger.attach(klass)
      PollTrigger.attach(klass)
    end

    module ClassMethods
      def netsuite_poll(opts = {})
        RecordSync::PollManager.poll(self, opts)
      end

      attr_accessor :netsuite_custom_record_type_id
      attr_accessor :netsuite_sync_options

      # TODO is there a better way to implement callback chains?
      #      https://github.com/rails/rails/blob/0c0f278ab20f3042cdb69604166e18a61f8605ad/activesupport/lib/active_support/callbacks.rb#L491

      def before_netsuite_push(callback = nil, &block)
        self.netsuite_settings[:before_netsuite_push] << (callback || block) if callback || block
        self.netsuite_settings[:before_netsuite_push]
      end

      def after_netsuite_push(callback = nil, &block)
        self.netsuite_settings[:after_netsuite_push] << (callback || block) if callback || block
        self.netsuite_settings[:after_netsuite_push]
      end

      def after_netsuite_pull(callback = nil, &block)
        self.netsuite_settings[:after_netsuite_pull] << (callback || block) if callback || block
        self.netsuite_settings[:after_netsuite_pull]
      end

      def netsuite_field_map(field_mapping = nil)
        if !field_mapping.nil?
          self.netsuite_settings[:netsuite_field_map] = field_mapping
        end

        self.netsuite_settings[:netsuite_field_map]
      end

      def netsuite_field_hints(list = nil)
        if !list.nil?
          self.netsuite_settings[:netsuite_field_hints] = list
        end

        self.netsuite_settings[:netsuite_field_hints]
      end

      # TODO persist type for CustomRecordRef
      def netsuite_record_class(record_class = nil, custom_record_type_id = nil)
        if !record_class.nil?
          self.netsuite_settings[:netsuite_record_class] = record_class
          self.netsuite_custom_record_type_id = custom_record_type_id
        end

        self.netsuite_settings[:netsuite_record_class]
      end

      # there is a model level of this method in order to be based on the model level record class
      def netsuite_custom_record?
        self.netsuite_record_class == NetSuite::Records::CustomRecord
      end

      # :read, :write_only, :read_write
      def netsuite_sync(flag = nil, opts = {})
        if !flag.nil?
          self.netsuite_sync_options = opts
          self.netsuite_settings[:netsuite_sync] = flag
        end

        self.netsuite_settings[:netsuite_sync]
      end
    end

    module InstanceMethods
      attr_writer :netsuite_manual_fields

      def netsuite_manual_fields
        @netsuite_manual_fields ||= []
      end

      # these methods are here for easy model override

      def netsuite_sync_options
        self.class.netsuite_sync_options
      end

      def netsuite_sync
        self.class.netsuite_sync
      end

      def netsuite_record_class
        self.class.netsuite_record_class
      end

      def netsuite_field_map
        self.class.netsuite_field_map
      end

      def netsuite_field_hints
        self.class.netsuite_field_hints
      end

      # assumes netsuite_id field on activerecord

      def netsuite_pulling?
        @netsuite_pulling ||= false
      end

      def netsuite_pulled?
        @netsuite_pulled ||= false
      end

      def netsuite_async_jobs?
        self.netsuite_sync_options[:sync_mode] == :async || (self.netsuite_sync_options[:sync_mode].blank? && NetSuiteRails::Configuration.netsuite_sync_mode == :async)
      end

      # TODO need to support the opts hash
      def netsuite_pull(opts = {})
        netsuite_extract_from_record(netsuite_pull_record)

        if self.netsuite_async_jobs?
          # without callbacks?
          self.save
        end
      end

      def netsuite_pull_record
        # TODO support use_external_id / netsuite_external_id

        if netsuite_custom_record?
          NetSuite::Records::CustomRecord.get(
            internal_id: self.netsuite_id,
            type_id: self.class.netsuite_custom_record_type_id
          )
        else
          self.netsuite_record_class.get(self.netsuite_id)
        end
      end

      def netsuite_push(opts = {})
        NetSuiteRails::RecordSync::PushManager.push(self, opts)
      end

      # TODO move this login into separate service object
      def netsuite_extract_from_record(netsuite_record)
        Rails.logger.info "NetSuite: Pull #{netsuite_record.class} #{netsuite_record.internal_id}"

        @netsuite_pulling = true

        field_hints = self.netsuite_field_hints

        custom_field_list = self.netsuite_field_map[:custom_field_list] || {}

        all_field_list = self.netsuite_field_map.except(:custom_field_list) || {}
        all_field_list.merge!(custom_field_list)

        # TODO should have a helper module for common push/pull methods
        reflection_attributes = NetSuiteRails::RecordSync::PushManager.relationship_attributes_list(self)

        # handle non-collection associations
        association_keys = reflection_attributes.values.reject(&:collection?).map(&:name)

        all_field_list.each do |local_field, netsuite_field|
          is_custom_field = custom_field_list.keys.include?(local_field)

          if netsuite_field.is_a?(Proc)
            netsuite_field.call(self, netsuite_record, :pull)
            next
          end

          field_value = if is_custom_field
            netsuite_record.custom_field_list.send(netsuite_field).value rescue ""
          else
            netsuite_record.send(netsuite_field)
          end

          if field_value.nil?
            # TODO possibly nil out the local value?
            next
          end

          if association_keys.include?(local_field)
            field_value = reflection_attributes[local_field].
              klass.
              where(netsuite_id: field_value.internal_id).
              first_or_initialize
          elsif is_custom_field
            field_value = NetSuiteRails::RecordSync::PullManager.extract_custom_field_value(field_value)
          else
            # then it's not a custom field
          end

          # TODO should we just check for nil? vs present?

          if field_hints.has_key?(local_field) && !field_value.nil?
            field_value = NetSuiteRails::Transformations.transform(field_hints[local_field], field_value, :pull)
          end

          self.send(:"#{local_field}=", field_value)
        end

        netsuite_execute_callbacks(self.class.after_netsuite_pull, netsuite_record)

        @netsuite_pulling = false
        @netsuite_pulled = true
      end


      def new_netsuite_record?
        self.netsuite_id.blank?
      end

      def netsuite_custom_record?
        self.netsuite_record_class == NetSuite::Records::CustomRecord
      end

      # TODO this should be protected; it needs to be pushed down to the Push/Pull manager level

      def netsuite_execute_callbacks(list, record)
        list.each do |callback|
          if callback.is_a?(Symbol)
            self.send(callback, record)
          else
            instance_exec(record, &callback)
          end
        end
      end

    end

  end
end
