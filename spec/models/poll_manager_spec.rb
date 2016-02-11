require 'spec_helper'

describe NetSuiteRails::RecordSync::PollManager do
  include ExampleModels

  # TODO fake a couple items in the list

  let(:empty_search_results) { OpenStruct.new(results: [ OpenStruct.new(internal_id: 0) ]) }

  it "should poll record sync objects" do
  	allow(NetSuite::Records::Customer).to receive(:search).and_return(empty_search_results)

  	StandardRecord.netsuite_poll(import_all: true)

  	expect(NetSuite::Records::Customer).to have_received(:search)
  end

  skip "should poll and then get_list on saved search" do
    # TODO SS enabled record
    # TODO mock search to return one result
    # TODO mock out get_list
  end

  it "should poll list sync objects" do
  	allow(NetSuite::Records::CustomList).to receive(:get).and_return(OpenStruct.new(custom_value_list: OpenStruct.new(custom_value: [])))

  	StandardList.netsuite_poll(import_all: true)

  	expect(NetSuite::Records::CustomList).to have_received(:get)
  end

  it "should sync only available local records" do
    # disabling NS pull since this is treated as a record import (NS ID = exists, new_record? == true)
    NetSuiteRails::Configuration.netsuite_pull_disabled true
    StandardRecord.create! netsuite_id: 123
    NetSuiteRails::Configuration.netsuite_pull_disabled false

    allow(NetSuite::Records::Customer).to receive(:get_list).and_return([OpenStruct.new(internal_id: 123)])
    allow(NetSuiteRails::RecordSync::PollManager).to receive(:process_search_result_item)

    NetSuiteRails::PollTrigger.update_local_records

    expect(NetSuite::Records::Customer).to have_received(:get_list)
  end

  it 'runs netsuite_pull on a newly created record with a netsuite_id defined' do
    record = StandardRecord.new netsuite_id: 123
    allow(record).to receive(:netsuite_pull)

    record.save!

    expect(record).to have_received(:netsuite_pull)
  end
end
