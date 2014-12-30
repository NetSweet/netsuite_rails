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
end
