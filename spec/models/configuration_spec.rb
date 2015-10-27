require 'spec_helper'

describe NetSuiteRails::Configuration do
  it 'should disable netsuite push and pull' do
    NetSuiteRails::Configuration.netsuite_push_disabled true
    NetSuiteRails::Configuration.netsuite_pull_disabled false

    expect(NetSuiteRails::Configuration.netsuite_pull_disabled).to eq(false)
    expect(NetSuiteRails::Configuration.netsuite_push_disabled).to eq(true)
  end
end
