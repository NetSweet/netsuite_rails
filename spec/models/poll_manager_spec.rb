require 'spec_helper'

describe NetSuiteRails::RecordSync::PollManager do
  include ExampleModels

  # TODO fake a couple items in the list

  let(:empty_search_results) { OpenStruct.new(results: [ OpenStruct.new(internal_id: 0) ]) }

  describe 'polling ranges' do
    let(:updated_after) { DateTime.new(2016, 01, 01) }
    let(:updated_before) { DateTime.new(2016, 01, 02) }

    it 'does not restrict poll by date if import_all is specified' do
      expect(NetSuite::Records::Customer).to receive(:search)
        .with(hash_including(
          criteria: hash_including(
            basic: []
          )
        ))
        .and_return(empty_search_results)

      StandardRecord.netsuite_poll(import_all: true)
    end

    it 'restricts polling within a range' do
      expect(NetSuite::Records::Customer).to receive(:search)
        .with(hash_including(
          criteria: hash_including(
            basic: array_including(
              {
                field: 'lastModifiedDate',
                operator: 'within',
                value: [
                  updated_after,
                  updated_before
                ]
              }
            )
          )
        ))
        .and_return(empty_search_results)

      StandardRecord.netsuite_poll(
        last_poll: updated_after,
        updated_before: updated_before
      )
    end

    it 'restricts polling after a date' do
      expect(NetSuite::Records::Customer).to receive(:search)
        .with(hash_including(
          criteria: hash_including(
            basic: array_including(
              {
                field: 'lastModifiedDate',
                operator: 'after',
                value: updated_after
              }
            )
          )
        ))
        .and_return(empty_search_results)

      StandardRecord.netsuite_poll(last_poll: updated_after)
    end

    it 'allows the polling field to be customized' do
      expect(NetSuite::Records::Customer).to receive(:search)
        .with(hash_including(
          criteria: hash_including(
            basic: array_including(
              {
                field: 'lastQuantityAvailableChange',
                operator: 'after',
                value: updated_after
              }
            )
          )
        ))
        .and_return(empty_search_results)

      StandardRecord.netsuite_poll(last_poll: updated_after, netsuite_poll_field: 'lastQuantityAvailableChange')
    end
  end

  skip "should poll and then get_list on saved search" do
    # TODO SS enabled record
    # TODO mock search to return one result
    # TODO mock out get_list
  end

  it "should poll list sync objects" do
  	allow(NetSuite::Records::CustomList).to receive(:get)
      .and_return(OpenStruct.new(custom_value_list: OpenStruct.new(custom_value: [])))

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

  describe 'custom search criteria' do
    let(:basic_search_field) do
      {
        field: 'type',
        operator: 'anyOf',
        value: [ '_itemFulfillment' ]
      }
    end

    let(:advanced_search_criteria) do
      {
        createdFromJoin: [
          {
            field: 'type',
            operator: 'anyOf',
            value: [ '_transferOrder' ]
          }
        ]
      }
    end

    it 'should merge basic search criteria' do
      expect(NetSuite::Records::Customer).to receive(:search)
        .with(hash_including(
          criteria: hash_including(
            basic: array_including(
              basic_search_field
            )
          )
        ))
        .and_return(OpenStruct.new(results: []))

      NetSuiteRails::RecordSync::PollManager.poll(StandardRecord,
        criteria: [ basic_search_field ]
      )
    end

    it 'merges advanced and basic criteria' do
      expect(NetSuite::Records::Customer).to receive(:search)
        .with(hash_including(
          criteria: {
            basic: array_including(
              basic_search_field
            )
          }.merge(advanced_search_criteria)
        ))
        .and_return(OpenStruct.new(results: []))

      NetSuiteRails::RecordSync::PollManager.poll(StandardRecord,
        criteria: {
          basic: [ basic_search_field ]
        }.merge(advanced_search_criteria)
      )
    end

    it 'should merge join/advanced criteria' do
      expect(NetSuite::Records::Customer).to receive(:search)
        .with(hash_including(criteria: hash_including(advanced_search_criteria)))
        .and_return(OpenStruct.new(results: []))

      NetSuiteRails::RecordSync::PollManager.poll(StandardRecord,
        criteria: advanced_search_criteria
      )
    end
  end
end
