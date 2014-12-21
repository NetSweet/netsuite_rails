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

    def netsuite_instance_time_zone_offset(zone_offset = nil)
      if zone_offset.nil?
        attributes[:zone_offset] ||= -8
      else
        attributes[:zone_offset] = zone_offset
      end
    end

    def polling_page_size(size = nil)
      if size.nil?
        attributes[:size] ||= 1000
      else
        attributes[:size] = size
      end
    end

  end
end
