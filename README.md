[![Build Status](https://travis-ci.org/NetSweet/netsuite_rails.svg?branch=master)](https://travis-ci.org/NetSweet/netsuite_rails)

# NetSuite Rails

**Note:** Documentation is horrible... look at the code for details.

Build Ruby on Rails applications that effortlessly sync to NetSuite. Here's an example:

```ruby
class Item < ActiveRecord::Base
  include NetSuiteRails::RecordSync

  netsuite_record_class NetSuite::Records::InventoryItem
  netsuite_sync :read, frequency: 1.day
  netsuite_field_map({
    :item_number => :item_id,
    :name => :display_name
  })
end
```

## Installation

```ruby
gem 'netsuite_rails'
```

Install the database migration to persist poll timestamps:

```bash
rails g netsuite_rails:install
```

### Date & Time

```ruby
# set your timezone offset
NetSuiteRails::Configuration.netsuite_instance_time_zone_offset(-6)
```

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

```
after_netsuite_pull
before_netsuite_push
after_netsuite_push
```

### Syncing

```bash
rake netsuite:sync

rake netsuite:fresh_sync

rake netsuite:fresh_sync 
```

Caveats:

* If you have date time fields, or custom fields that will trigger `changed_attributes` this might cause issues when pulling an existing record
* `changed_attributes` doesn't work well with store

## Non-AR Backed Model

Implement `changed_attributes` in your non-AR backed model

## Testing

```ruby
# in spec_helper.rb
require 'netsuite_rails/spec/spec_helper'
```

## Author

* Michael Bianco @iloveitaly