module NetSuiteRails
  class PollTrigger

    class << self

      def attach(klass)
        @record_models ||= []
        @list_models ||= []

        if klass.include? RecordSync
          @record_models << klass
        elsif klass.include? ListSync
          @list_models << klass
        end
      end

      def sync(opts = {})
        record_models = opts[:record_models] || @record_models
        list_models = opts[:list_models] || @list_models

        list_models.each do |klass|
          Rails.logger.info "NetSuite: Syncing #{klass}"
          klass.netsuite_poll
        end

        record_models.each do |klass|
          sync_frequency = klass.netsuite_sync_options[:frequency] || 1.day

          if sync_frequency == :never
            Rails.logger.info "NetSuite: Not syncing #{klass.to_s}"
            next
          end

          last_class_poll = PollTimestamp.for_class(klass)
          poll_execution_time = DateTime.now

          # check if we've never synced before
          if last_class_poll.new_record?
            Rails.logger.info "NetSuite: Syncing #{klass} for the first time"
            klass.netsuite_poll({ import_all: true }.merge(opts))
          else
            # TODO look into removing the conditional parsing; I don't think this is needed
            last_poll_date = last_class_poll.value
            last_poll_date = DateTime.parse(last_poll_date) unless last_poll_date.is_a?(DateTime)

            if DateTime.now.to_i - last_poll_date.to_i > sync_frequency
              Rails.logger.info "NetSuite: Syncing #{klass} modified since #{last_poll_date}"
              klass.netsuite_poll({ last_poll: last_poll_date }.merge(opts))
            else
              Rails.logger.info "NetSuite: Skipping #{klass} because of syncing frequency"
              next
            end
          end

          last_class_poll.value = poll_execution_time
          last_class_poll.save!
        end
      end

      def update_local_records(opts = {})
        record_models = opts[:record_models] || @record_models
        list_models = opts[:list_models] || @list_models

        # TODO only records are supported right now
        # list_models.each do |klass|
        #   Rails.logger.info "NetSuite: Syncing #{klass}"
        #   klass.netsuite_poll
        # end

        record_models.each do |klass|
          NetSuiteRails::RecordSync::PollManager.update_local_records(klass, opts)
        end
      end
      
    end

  end
end
