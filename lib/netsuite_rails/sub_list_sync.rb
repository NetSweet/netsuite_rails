module NetSuiteRails
  module SubListSync

    def self.included(klass)
      klass.send(:extend, ClassMethods)

      NetSuiteRails::SyncTrigger.attach(klass)
    end

    # one issue here is that sublist items dont' have an internal ID until
    # they are created, but they are created in the context of a parent record

    # some sublists don't have an internal ID at all, from the docs:
    # "...non-keyed sublists contain no referencing keys (or handles)"
    # "...Instead, you must interact with the sublist as a whole.
    # In non-keyed sublists, the replaceAll attribute is ignored and behaves as if
    # it were set to TRUE for all requests. Consequently, an update operation is
    # similar to the add operation with respect to non-keyed sublists."

    module ClassMethods
      def netsuite_sublist_parent(parent = nil)
        if parent.nil?
          @netsuite_sublist_parent
        else
          @netsuite_sublist_parent = parent
        end
      end
    end

  end
end
