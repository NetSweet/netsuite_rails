[![Build Status](https://travis-ci.org/NetSweet/netsuite_rails.svg?branch=master)](https://travis-ci.org/NetSweet/netsuite_rails)

# NetSuite Rails

**Note:** Documentation is horrible... look at the code for details.

Build Ruby on Rails applications that effortlessly sync to NetSuite. Here's an example:

```ruby
class Item < ActiveRecord::Base
  include NetSuiteRails::RecordSync

  # specify the NS record that your rails model maps to
  netsuite_record_class NetSuite::Records::InventoryItem

  netsuite_sync :read_write,
    # specify the frequency that your app should poll NetSuite for updates
    frequency: 1.day,
    # it's possible to base syncing off of a saved search. Be sure that "Internal ID" is one of your search result columns
    saved_search_id: 123,
    # limit pushing/pulling to/from NetSuite based on custom conditionals
    if: -> { true },
    pull_if: -> { true }
    

  # local => remote field mapping
  netsuite_field_map({
    :item_number => :item_id,
    :name => :display_name
  })
end
```

Your ruby model:

* Needs to have a `netsuite_id` & `netsuite_id=` method
* Does not need to be an `ActiveRecord` model. If you don't use ActiveRecord you have to implement: TODO


## Installation

```ruby
gem 'netsuite_rails'
```

Install the database migration to persist poll timestamps:

```bash
rails g netsuite_rails:install
```

This helps netsuite_rails to know when the last time your rails DB was synced with the NS.

## Date


## Time

"Time of Day" fields in NetSuite are especially tricky. To ensure that times don't shift when you push them to NetSuite here are some tips:

1. Take a look at the company time zone setup. This is in Setup
2. Ensure your WebService's Employee record has either:
  * No time zone set
  * The same time zone as the company
3. Ensure that the WebService's GUI preferences have the same time zone settings as the company. This effects how times are translated via SuiteTalk.
4. Set the `netsuite_instance_time_zone_offset` setting to your company's time zone

```ruby
# set your timezone offset
NetSuiteRails::Configuration.netsuite_instance_time_zone_offset(-6)
```

### Changing WebService User's TimeZone Preferences

It might take a couple hours for time zone changes to take effect. From my experience, either the time zone changes have some delay associated with them or the time zone implementation is extremely buggy.

## Usage

### Syncing Options

```
netsuite_record_class NetSuite::Records::Customer
netsuite_record_class NetSuite::Records::CustomRecord, 123

netsuite_sync: :read
netsuite_sync: :read_write
netsuite_sync: :aggressive

netsuite_sync: :read, frequency: :never
netsuite_sync: :read, frequency: 5.minutes
netsuite_sync: :read, if: -> { self.condition_met? }

```

When using a proc in a NS mapping, you are responsible for setting local and remote values

The default sync frequency is [one day](https://github.com/NetSweet/netsuite_rails/blob/c453326a4190e68a2fd9d7690b2b1f2f105ec8b9/lib/netsuite_rails/poll_trigger.rb#L27).

for pushing tasks to DJ https://github.com/collectiveidea/delayed_job/wiki/Rake-Task-as-a-Delayed-Job

`:if` for controlling when syncing occurs

Easily disable/enable syncing via env vars:

```ruby
NetSuiteRails.configure do
  netsuite_pull_disabled ENV['NETSUITE_PULL_DISABLED'].present? && ENV['NETSUITE_PULL_DISABLED'] == "true"
  netsuite_push_disabled ENV['NETSUITE_PUSH_DISABLED'].present? && ENV['NETSUITE_PUSH_DISABLED'] == "true"

  if ENV['NETSUITE_DISABLE_SYNC'].present? && ENV['NETSUITE_DISABLE_SYNC'] == "true"
    netsuite_pull_disabled true
    netsuite_push_disabled true
  end
end

```

### Hooks

```ruby
# the netsuite record is passed a single argument to this block (or method reference)
# this provides the opportunity to set custom fields or run custom logic to prepare
# the record for the NetSuite envoirnment
before_netsuite_push
after_netsuite_push

# netsuite_pulling? is true when this callback is executed
after_netsuite_pull
```

### Rake Tasks for Syncing

```bash
# update & create local records modified in netsuite sync the last sync time
rake netsuite:sync

# pull all records in NetSuite and update/create local records
rake netsuite:fresh_sync

# only update records that have already been synced
rake netsuite:sync_local RECORD_MODELS=YourModel LIST_MODELS=YourListModel
```

Caveats:

* If you have date time fields, or custom fields that will trigger `changed_attributes` this might cause issues when pulling an existing record
* `changed_attributes` doesn't work well with `store`s

### Delayed Job

The more records that use netsuite_rails, the longer you'll need your job timeout to be:

```ruby
# config/initializers/delayed_job.rb
Delayed::Worker.max_run_time = 80.minutes
```

## Non-AR Backed Model

Implement `changed_attributes` in your non-AR backed model

## Testing

```ruby
# in spec_helper.rb
require 'netsuite_rails/spec/spec_helper'
```

## Author

* Michael Bianco @iloveitaly
