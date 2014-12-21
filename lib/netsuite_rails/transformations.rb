module NetSuiteRails
  module Transformations
    class << self

      def transform(type, value)
        self.send(type, value)
      end

      # NS limits firstname fields to 33 characters
      def firstname(firstname)
        firstname[0..33]
      end

      def phone(phone)
        formatted_phone = phone.strip
          .gsub(/ext(ension)?/, 'x')
          .gsub(/[^0-9x ]/, '')
          .gsub(/[ ]{2,}/m, ' ')
        
        formatted_phone.gsub!(/x.*$/, '') if formatted_phone.size > 22

        formatted_phone
      end

      # NS will throw an error if whitespace bumpers the email string
      def email(email)
        email.strip
      end

      # https://www.reinteractive.net/posts/168-dealing-with-timezones-effectively-in-rails
      # http://stackoverflow.com/questions/16818180/ruby-rails-how-do-i-change-the-timezone-of-a-time-without-changing-the-time
      # http://alwayscoding.ca/momentos/2013/08/22/handling-dates-and-timezones-in-ruby-and-rails/

      def date(date)
        date.change(offset: "-07:00", hour: 24 - (8 + NetSuiteRails::Configuration.netsuite_instance_time_zone_offset))
      end

      def datetime(datetime)
        datetime.change(offset: "-08:00") - (8 + NetSuiteRails::Configuration.netsuite_instance_time_zone_offset).hours
      end

    end
  end
end