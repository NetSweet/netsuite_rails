class CreateNetsuitePollTimestamps < ActiveRecord::Migration
  def change
    create_table :netsuite_poll_timestamps do |t|
      t.string     :name, :limit => 100
      t.text       :value
      t.string     :key
      t.timestamps
    end

    add_index :netsuite_poll_timestamps, [:key], :name => 'index_netsuite_poll_timestamps_on_key', :unique => true
  end
end
