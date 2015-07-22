module NetSuiteRails
  module Transformations
    class << self

      # accepts an optional direction flag (:pull or :push) as a third parameter
      def transform(type, *value)
        self.send(type, *value)
      end

      # NS limits firstname fields to 33 characters
      def firstname(firstname, direction = nil)
        firstname[0..33]
      end

      def phone(phone, direction = nil)
        formatted_phone = phone.
          strip.
          gsub(/ext(ension)?/, 'x').
          # remove anything that isn't a extension indicator or a number
          gsub(/[^0-9x]/, '').
          # if the first part of the phone # is 10 characters long and starts with a 1 the 22 char error is thrown
          gsub(/^1([0-9]{10})/, '\1')

        # eliminate the extension if the number is still too long
        formatted_phone.gsub!(/x.*$/, '') if formatted_phone.size > 22

        formatted_phone
      end

      # NS will throw an error if whitespace bumpers the email string
      def email(email, direction = nil)
        email.strip
      end

      # https://www.reinteractive.net/posts/168-dealing-with-timezones-effectively-in-rails
      # http://stackoverflow.com/questions/16818180/ruby-rails-how-do-i-change-the-timezone-of-a-time-without-changing-the-time
      # http://alwayscoding.ca/momentos/2013/08/22/handling-dates-and-timezones-in-ruby-and-rails/

      def date(date, direction = :push)
        case direction
        when :push
          dst_offset = Time.now.in_time_zone( Time.zone ).dst? ? 1 : 0
          # dates in NS are really datetimes on the backend, need to set the timezone on them
          date.to_datetime
              .change(offset: (NetSuiteRails::Configuration.netsuite_instance_time_zone_offset +
                              dst_offset).to_s)
        when :pull
          # see comment above
          date.in_time_zone( Time.zone ).to_date
        else
          raise "Unknown sync direction #{direction.to_s} for NetSuiteRails::Transformations date transfomation"
        end
      end

      def datetime(datetime, direction = :push)
        case direction
        when :push
          dst_offset = Time.now.in_time_zone( Time.zone ).dst? ? 1 : 0
          netsuite_offset = Configuration.netsuite_instance_time_zone_offset + dst_offset
          datetime.change(offset: Time.zone.formatted_offset)
                  .in_time_zone( ActiveSupport::TimeZone[netsuite_offset] )
        when :pull
          # ActiveRecord saves datetimes in UTC
          binding.pry
          converted_time = datetime.in_time_zone( Time.zone )
          DateTime.new.change(offset: 0,
                              year: Time.now.year,
                              hour: converted_time.hour,
                              min: converted_time.min)
        else
          raise "Unknown sync direction #{direction.to_s} for NetSuiteRails::Transformations datetime transfomation"
        end
      end

    end
  end
end
