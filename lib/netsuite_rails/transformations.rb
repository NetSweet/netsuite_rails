module NetSuiteRails
  module Transformations
    class << self

      def transform(type, value, direction)
        self.send(type, value, direction)
      end

      # gift certificate codes have a maximum of 9 characters
      def gift_card_code(code, direction = :push)
        if direction == :push
          code[0..8]
        else
          code
        end
      end

      # NS limits firstname fields to 33 characters
      def firstname(firstname, direction = :push)
        if direction == :push
          firstname[0..33]
        else
          firstname
        end
      end

      def integer(number, direction = :push)
        number.to_i
      end

      # TODO consider adding precision?
      def float(number, direction = :push)
        number.to_f
      end

      def phone(phone, direction = :push)
        if direction == :push
          return nil if phone.nil?

          formatted_phone = phone.
            strip.
            gsub(/ext(ension)?/, 'x').
            # remove anything that isn't a extension indicator or a number
            gsub(/[^0-9x]/, '').
            # if the first part of the phone # is 10 characters long and starts with a 1 the 22 char error is thrown
            gsub(/^1([0-9]{10})/, '\1')

          # eliminate the extension if the number is still too long
          formatted_phone.gsub!(/x.*$/, '') if formatted_phone.size > 22

          # phone numbers less than 7 digits throw a fatal error
          if formatted_phone.size < 7
            return nil
          end

          formatted_phone
        else
          phone
        end
      end

      # NS will throw an error if whitespace bumpers the email string
      def email(email, direction = :push)
        if direction == :push
          # any whitespace will cause netsuite to throw a fatal error
          email = email.gsub(' ', '')

          # TODO consider throwing an exception instead of returning nil?
          # netsuite will throw a fatal error if a valid email address is not sent
          # http://stackoverflow.com/questions/742451/what-is-the-simplest-regular-expression-to-validate-emails-to-not-accept-them-bl
          if email !~ /.+@.+\..+/
            return nil
          end

          email = email.
            # an error will be thrown if period is on the end of a sentence
            gsub(/[^A-Za-z]+$/, '').
            # any commas in the email with throw an error
            gsub(',', '')

          email
        else
          email
        end
      end

      # https://www.reinteractive.net/posts/168-dealing-with-timezones-effectively-in-rails
      # http://stackoverflow.com/questions/16818180/ruby-rails-how-do-i-change-the-timezone-of-a-time-without-changing-the-time
      # http://alwayscoding.ca/momentos/2013/08/22/handling-dates-and-timezones-in-ruby-and-rails/

      def date(date, direction = :push)
        if direction == :push
          # setting the hour to noon eliminates the chance that some strange timezone offset
          # shifting would cause the date to drift into the next or previous day
          date.to_datetime.change(offset: "-07:00", hour: 12)
        else
          date.change(offset: Time.zone.formatted_offset)
        end
      end

      def datetime(datetime, direction = :push)
        if direction == :push
          datetime.change(offset: "-08:00", year: 1970, day: 01, month: 01) - (8 + NetSuiteRails::Configuration.netsuite_instance_time_zone_offset).hours
        else
          datetime = datetime.change(offset: Time.zone.formatted_offset) + (8 + NetSuiteRails::Configuration.netsuite_instance_time_zone_offset).hours
          datetime
        end
      end

    end
  end
end
