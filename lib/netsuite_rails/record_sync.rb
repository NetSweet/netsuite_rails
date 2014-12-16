module NetSuiteRails
  module RecordSync
    @@netsuite_disable_sync = false

    def self.netsuite_disable_sync(flag = nil)
      @netsuite_disable_sync = flag unless flag.nil?
      @netsuite_disable_sync
    end

    def self.included(klass)
      klass.send(:extend, ClassMethods)

      SyncTrigger.attach(klass)
      PollManager.attach(klass)
    end

    module ClassMethods
      def netsuite_poll(opts = {})
        RecordSync::PullManager.poll(self, opts)
      end

      attr_accessor :netsuite_custom_record_type_id
      attr_accessor :netsuite_sync_options
      attr_accessor :netsuite_credentials

      # TODO is there a better way to implement callback chains?
      #      https://github.com/rails/rails/blob/0c0f278ab20f3042cdb69604166e18a61f8605ad/activesupport/lib/active_support/callbacks.rb#L491

      def before_netsuite_push(callback = nil, &block)
        @before_netsuite_push ||= []
        @before_netsuite_push << (callback || block) if callback || block
        @before_netsuite_push
      end

      def after_netsuite_push(callback = nil, &block)
        @after_netsuite_push ||= []
        @after_netsuite_push << (callback || block) if callback || block
        @after_netsuite_push
      end

      def after_netsuite_pull(callback = nil, &block)
        @after_netsuite_pull ||= []
        @after_netsuite_pull << (callback || block) if callback || block
        @after_netsuite_pull
      end

      def netsuite_field_map(field_mapping = nil)
        if field_mapping.nil?
          @netsuite_field_map ||= {}
        else
          @netsuite_field_map = field_mapping
        end

        @netsuite_field_map
      end

      def netsuite_local_fields
        @netsuite_field_map.except(:custom_field_list).keys + (@netsuite_field_map[:custom_field_list] || {}).keys
      end

      def netsuite_field_hints(list = nil)
        if list.nil?
          @netsuite_field_hints ||= {}
        else
          @netsuite_field_hints = list
        end
      end

      # TODO persist type for CustomRecordRef
      def netsuite_record_class(record_class = nil, custom_record_type_id = nil)
        if record_class.nil?
          @netsuite_record_class
        else
          @netsuite_record_class = record_class
          @netsuite_custom_record_type_id = custom_record_type_id
        end
      end

      # there is a model level of this method in order to be based on the model level record class
      def netsuite_custom_record?
        self.netsuite_record_class == NetSuite::Records::CustomRecord
      end

      # :read_only, :aggressive (push & update on save), :write_only, :read_write
      def netsuite_sync(flag = nil, opts = {})
        if flag.nil?
          @netsuite_sync_options ||= {}
          @netsuite_sync ||= :read_only
        else
          @netsuite_sync = flag
          @netsuite_sync_options = opts
        end
      end
    end

    attr_accessor :netsuite_manual_fields

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

    def netsuite_pull
      netsuite_extract_from_record(netsuite_pull_record)
    end

    def netsuite_pull_record
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

    def netsuite_extract_from_record(netsuite_record)
      @netsuite_pulling = true

      field_hints = self.netsuite_field_hints

      custom_field_list = self.netsuite_field_map[:custom_field_list] || {}

      all_field_list = self.netsuite_field_map.except(:custom_field_list) || {}
      all_field_list.merge!(custom_field_list)

      # self.netsuite_normalize_datetimes(:pull)

      # handle non-collection associations
      association_keys = self.reflections.values.reject(&:collection?).map(&:name)

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

        if field_value.blank?
          # TODO possibly nil out the local value?
          next
        end

        if association_keys.include?(local_field)
          field_value = self.reflections[local_field].klass.where(netsuite_id: field_value.internal_id).first_or_initialize
        elsif is_custom_field
          # TODO I believe this only handles a subset of all the possibly CustomField values
          if field_value.present? && field_value.is_a?(Hash) && field_value.has_key?(:name)
            field_value = field_value[:name]
          end

          if field_value.present? && field_value.is_a?(NetSuite::Records::CustomRecordRef)
            field_value = field_value.attributes[:name]
          end
        else
          # then it's not a custom field
        end

        # TODO should we just check for nil? vs present?
        # TODO don't need to transform any supported values on :pull yet...

        # if field_hints.has_key?(local_field) && field_value.present?
        #   case field_hints[local_field]
        #   when :datetime
        #     field_value = NetSuite::Ascension::Utilities.normalize_datetime_from_netsuite(field_value)
        #   end
        # end

        self.send(:"#{local_field}=", field_value)
      end

      netsuite_execute_callbacks(self.class.after_netsuite_pull, netsuite_record)

      @netsuite_pulling = false
      @netsuite_pulled = true

      # return netsuite record for debugging
      netsuite_record
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
