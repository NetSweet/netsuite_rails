module NetSuiteRails
  module UrlHelper

    # TODO create a xxx_netsuite_url helper generator

    def self.netsuite_url(record = self)
      prefix = "https://system#{".sandbox" if NetSuite::Configuration.sandbox}.netsuite.com/app"

      record_class = record.netsuite_record_class
      internal_id = record.netsuite_id

      # https://system.sandbox.netsuite.com/app/common/scripting/scriptrecordlist.nl
      # https://system.sandbox.netsuite.com/app/common/scripting/script.nl

      if record.netsuite_custom_record?
        "#{prefix}/common/custom/custrecordentry.nl?id=#{internal_id}&rectype=#{record.class.netsuite_custom_record_type_id}"
      elsif [ NetSuite::Records::InventoryItem, NetSuite::Records::NonInventorySaleItem, NetSuite::Records::AssemblyItem].include?(record_class)
        "#{prefix}/common/item/item.nl?id=#{internal_id}"
      elsif record_class == NetSuite::Records::Task
        "#{prefix}/crm/calendar/task.nl?id=#{internal_id}"
      elsif record_class == NetSuite::Records::Customer
        "#{prefix}/common/entity/custjob.nl?id=#{internal_id}"
      elsif record_class == NetSuite::Records::Contact
        "#{prefix}/common/entity/contact.nl?id=#{internal_id}"
      elsif [ NetSuite::Records::SalesOrder, NetSuite::Records::Invoice, NetSuite::Records::CustomerRefund ].include?(record_class)
        "#{prefix}/accounting/transactions/transaction.nl?id=#{internal_id}"
      end
    end

  end
end
