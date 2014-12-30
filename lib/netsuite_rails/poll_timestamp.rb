module NetSuiteRails
  class PollTimestamp < ActiveRecord::Base
    serialize :value

    validates :key, presence: true, uniqueness: true

    def self.for_class(klass)
      self.where(key: "netsuite_poll_#{klass.to_s.downcase}timestamp").first_or_initialize
    end

    def self.table_name_prefix
      'netsuite_'
    end
    
  end
end
