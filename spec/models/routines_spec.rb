require 'spec_helper'

# TODO https://github.com/NetSweet/netsuite_rails/issues/16
# there are still some unresolved issues with NS datetime/date conversions
# the tests + implementation may still not be correct.

describe NetSuiteRails::Routines do
  describe '#company_contact_match' do
    it "matches on first and last name first" do

    end

    it "matches on email if no name match is found" do

    end

    it "returns nil if no match is found" do

    end

    # TODO also handle updating contact information
  end
end
