module NetSuiteRails
  module Configuration
    extend self

    def reset!
      attributes.clear
    end

    def attributes
      @attributes ||= {}
    end

    def netsuite_sync_mode(mode = nil)
      if mode.nil?
        attributes[:sync_mode] ||= :none
      else
        attributes[:sync_mode] = mode
      end
    end

    def netsuite_push_disabled(flag = nil)
      if flag.nil?
        attributes[:flag] ||= false
      else
        attributes[:flag] = flag
      end
    end

    def netsuite_pull_disabled(flag = nil)
      if flag.nil?
        attributes[:flag] ||= false
      else
        attributes[:flag] = flag
      end
    end

  end
end
