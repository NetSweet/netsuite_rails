namespace :netsuite do

  def generate_options
    opts = {
      skip_existing: ENV['SKIP_EXISTING'].present? && ENV['SKIP_EXISTING'] == "true"
    }

    if !ENV['RECORD_MODELS'].nil?
      opts[:record_models] = ENV['RECORD_MODELS'].split(',').map(&:constantize)
    end

    if !ENV['LIST_MODELS'].nil?
      opts[:list_models] = ENV['LIST_MODELS'].split(',').map(&:constantize)
    end

    # field values might change on import because of remote data structure changes
    # stop all pushes on sync & fresh_sync to avoid pushing up data that really hasn't
    # changed for each record

    # TODO make push disabled configurable
    NetSuiteRails::Configuration.netsuite_push_disabled true

    opts
  end

  desc "Sync all NetSuite records using import_all"
  task :fresh_sync => :environment do
    if ENV['SKIP_EXISTING'].blank?
      ENV['SKIP_EXISTING'] = "true"
    end

    opts = generate_options
    opts[:record_models].each do |record_model|
      NetSuiteRails::PollTimestamp.for_class(record_model).delete
    end

    Rake::Task["netsuite:sync"].invoke
  end

  desc "sync all netsuite records"
  task :sync => :environment do
    # need to eager load to ensure that all classes are loaded into the poll manager
    Rails.application.eager_load!

    NetSuiteRails::PollTrigger.sync(generate_options)
  end

  desc "sync all local netsuite records"
  task :sync_local => :environment do
    NetSuiteRails::PollTrigger.update_local_records(generate_options)
  end

  task field_usage_report: :environment do |t|
    Rails.application.eager_load!

    NetSuiteRails::PollTrigger.instance_variable_get('@record_models').each do |record_model|
      puts record_model.to_s

      # TODO add the ability to document which fields

      standard_fields = record_model.netsuite_field_map.values - [record_model.netsuite_field_map[:custom_field_list]]
      custom_fields = record_model.netsuite_field_map[:custom_field_list].values

      standard_fields.reject! { |f| f.is_a?(Proc) }
      custom_fields.reject! { |f| f.is_a?(Proc) }

      if custom_fields.present?
        puts "Custom Fields: #{custom_fields.join(', ')}"
      end

      if standard_fields.present?
        puts "Standard Fields: #{standard_fields.join(', ')}"
      end

      puts ""
    end
  end

end
