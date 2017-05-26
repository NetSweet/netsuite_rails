module NetSuiteRails
  module Routines
    module CompanyContactMatch
      extend self

      def match(company_customer, contact_data, update_contact_name: false, update_contact_email: false)
        search = NetSuite::Records::Contact.search({
          customerJoin: [
            {
              field: 'internalId',
              operator: 'anyOf',
              value: [
                NetSuite::Records::Customer.new(internal_id: company_customer.internal_id)
              ]
            }
          ],

          preferences: {
            page_size: 1_000
          }
        })

        match_data = {
          email: (contact_data[:email] || '').dup,
          first_name: (contact_data[:first_name] || '').dup,
          last_name: (contact_data[:last_name] || '').dup
        }

        match_data.
          values.
          each(&:strip!).
          each(&:downcase!)

        # TODO search error checking

        # try name match first; NS will throw an error if a contact is created or updated if the name already exists
        search.results.each do |contact|
          contact_first_name = contact.first_name.downcase.strip rescue ''
          contact_last_name = contact.last_name.downcase.strip rescue ''

          # if no email match & name data is present try fuzzy matching
          if match_data[:first_name] && match_data[:last_name] && !contact_first_name.empty? && !contact_last_name.empty?

            # TODO add logging for these interactions with NetSuite
            if update_contact_email && order_payload[:email].present? && contact.email != order_payload[:email]
              if !result.update(email: order_payload[:email])
                raise NetSuiteRails::Error, "error updating email on contact"
              end
            end

            # TODO consider `self.fuzzy_name_matches?(contact_first_name, contact_last_name, match_data[:first_name], match_data[:last_name])`
            if contact_first_name == match_data[:first_name] && contact_last_name == match_data[:last_name]
              return contact
            end
          end
        end

        # try email match second
        search.results.each do |contact|
          contact_first_name = contact.first_name.downcase.strip rescue ''
          contact_last_name = contact.last_name.downcase.strip rescue ''

          # match on email
          if match_data[:email] && contact.email && contact.email.downcase.strip == match_data[:email]
            if match_data[:first_name] != contact_first_name || match_data[:last_name] != contact_last_name
              # first name and/or last name did not match the input, update contact information

              if update_contact_name
                result = contact.update(
                  # use the first & last name from the payload; the match_data versions have been transformed
                  first_name: order_payload[:shipping_address][:firstname],
                  last_name: order_payload[:shipping_address][:lastname]
                )

                unless result
                  raise NetSuiteRails::Error, 'error updating name on contact placing order'
                end
              end
            end

            return contact
          end
        end

        nil
      end

      # TODO consider optionally using fuzzy name matches in the future
      # def fuzzy_name_matches?(first_name_1, last_name_1, first_name_2, last_name_2)
      #   @fuzzy_comparison ||= FuzzyStringMatch::JaroWinkler.create

      #   # Jarow-Winkler returns 1 for exact match
      #   if @fuzzy_comparison.getDistance(last_name_1, last_name_2) > 0.90
      #     # check for a match on the first name
      #     if @fuzzy_comparison.getDistance(first_name_1, first_name_2) > 0.90
      #       return true
      #     end

      #     # if fuzzy on first name failed; try to see if there are any nickname equivilents
      #     if Monikers.equivalents?(first_name_1, first_name_2)
      #       return true
      #     end
      #   end

      #   false
      # end

    end
  end
end
