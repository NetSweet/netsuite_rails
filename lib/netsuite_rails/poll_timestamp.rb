module NetSuiteRails
  class PollTimestamp < ActiveRecord::Base
    serialize :value

    validates :key, presence: true, uniqueness: true

    def self.table_name_prefix
      'netsuite_'
    end
  end
end
