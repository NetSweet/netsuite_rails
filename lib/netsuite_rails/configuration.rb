module NetSuiteRails
  module Configuration
    extend self

    NETSUITE_MAX_PAGE_SIZE = 1000

    def reset!
      attributes.clear
    end

    def attributes
      @attributes ||= {}
    end

    def netsuite_sync_mode(mode = nil)
      if mode.nil?
        attributes[:sync_mode] ||= :async
      else
        attributes[:sync_mode] = mode
      end
    end

    def netsuite_push_disabled(flag = nil)
      if flag.nil?
        attributes[:push_disabled] = false if attributes[:push_disabled].nil?
        attributes[:push_disabled]
      else
        attributes[:push_disabled] = flag
      end
    end

    def netsuite_pull_disabled(flag = nil)
      if flag.nil?
        attributes[:pull_disabled] = false if attributes[:pull_disabled].nil?
        attributes[:pull_disabled]
      else
        attributes[:pull_disabled] = flag
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
        attributes[:size] ||= NETSUITE_MAX_PAGE_SIZE
      else
        attributes[:size] = size
      end
    end

  end
end
