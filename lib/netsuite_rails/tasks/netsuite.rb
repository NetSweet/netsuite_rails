namespace :netsuite do

  desc "Sync all NetSuite records using import_all"
  task :fresh_sync => :environment do
    NetSuiteRails::PollTimestamp.delete_all

    ENV['SKIP_EXISTING'] = "true"

    Rake::Task["netsuite:sync"].invoke
  end

  desc "sync all netsuite records"
  task :sync => :environment do
    # need to eager load to ensure that all classes are loaded into the poll manager
    Rails.application.eager_load!

    NetSuiteRails::PollManager.sync skip_existing: ENV['SKIP_EXISTING'].present?
  end

end

# TODO could use this for a "updates local records with a netsuite_id with remote NS data"
# Model.select([:netsuite_id, :id]).find_in_batches do |batch|
#   NetSuite::Records::CustomRecord.get_list(
#     list: batch.map(&:netsuite_id),
#     type_id: Model::NETSUITE_RECORD_TYPE_ID
#   ).each do |record|
#     model = Model.find_by_netsuite_id(record.internal_id)
#     model.extract_from_netsuite_record(record)
#     model.save!
#   end      
# end