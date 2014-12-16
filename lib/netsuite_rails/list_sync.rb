module NetSuiteRails
  module ListSync

    def self.included(klass)
      klass.send(:extend, ClassMethods)

      PollManager.attach(klass)
    end

    module ClassMethods
      def netsuite_list_id(internal_id = nil)
        if internal_id.nil?
          @netsuite_list_id
        else
          @netsuite_list_id = internal_id
        end
      end

      def netsuite_poll(opts = {})
        NetSuiteRails::ListSync::PullManager.poll(self, opts)
      end
    end

  end
end
