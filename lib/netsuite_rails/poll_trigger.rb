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
            Rails.logger.info "Not syncing #{klass.to_s}"
            next
          end

          Rails.logger.info "NetSuite: Syncing #{klass.to_s}"
          
          preference = PollTimestamp.for_class(klass)

          # check if we've never synced before
          if preference.new_record?
            klass.netsuite_poll({ import_all: true }.merge(opts))
          else
            # TODO look into removing the conditional parsing; I don't think this is needed
            last_poll_date = preference.value
            last_poll_date = DateTime.parse(last_poll_date) unless last_poll_date.is_a?(DateTime)

            if DateTime.now.to_i - last_poll_date.to_i > sync_frequency
              Rails.logger.info "NetSuite: Syncing #{klass} modified since #{last_poll_date}"
              klass.netsuite_poll({ last_poll: last_poll_date }.merge(opts))
            else
              Rails.logger.info "NetSuite: Skipping #{klass} because of syncing frequency"
            end
          end

          preference.value = DateTime.now
          preference.save!
        end
      end
      
    end

  end
end
