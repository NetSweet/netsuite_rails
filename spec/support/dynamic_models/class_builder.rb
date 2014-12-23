# https://github.com/thoughtbot/shoulda-matchers/raw/2a4b9f1e163fa9c5b84f223962d5f8e099032420/spec/support/class_builder.rb

module ClassBuilder
  def self.included(example_group)
    example_group.class_eval do
      after do
        teardown_defined_constants
      end
    end
  end

  def define_class(class_name, base = Object, &block)
    class_name = class_name.to_s.camelize

    if Object.const_defined?(class_name)
      Object.__send__(:remove_const, class_name)
    end

    # FIXME: ActionMailer 3.2 calls `name.underscore` immediately upon
    # subclassing. Class.new.name == nil. So, Class.new(ActionMailer::Base)
    # errors out since it's trying to do `nil.underscore`. This is very ugly but
    # allows us to test against ActionMailer 3.2.x.
    eval <<-A_REAL_CLASS_FOR_ACTION_MAILER_3_2
    class ::#{class_name} < #{base}
    end
    A_REAL_CLASS_FOR_ACTION_MAILER_3_2

    Object.const_get(class_name).tap do |constant_class|
      constant_class.unloadable

      if block_given?
        constant_class.class_eval(&block)
      end

      if constant_class.respond_to?(:reset_column_information)
        constant_class.reset_column_information
      end
    end
  end

  def teardown_defined_constants
    ActiveSupport::Dependencies.clear
  end
end

RSpec.configure do |config|
  config.include ClassBuilder
end