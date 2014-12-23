[![Build Status](https://travis-ci.org/NetSweet/netsuite_rails.svg?branch=master)](https://travis-ci.org/NetSweet/netsuite_rails)

# NetSuite Rails

**Note:** Documentation is horrible... look at the code for details.

Build custom Ruby on Rails applications that sync to NetSuite.

## Installation

```ruby
gem 'netsuite_rails'
```

Install the database migration for poll timestamps

```bash
rails g netsuite_rails:install
```

### Date & Time

```ruby
# set your timezone offset
NetSuiteRails::Configuration.netsuite_instance_time_zone_offset(-6)
```

## Usage

modes: :read, :read_write, :aggressive

When using a proc in a NS mapping, you are responsible for setting local and remote values

for pushing tasks to DJ https://github.com/collectiveidea/delayed_job/wiki/Rake-Task-as-a-Delayed-Job

`:if` for controlling when syncing occurs

TODO hooks for before/after push/pull

### Syncing

```bash
rake netsuite:sync

rake netsuite:fresh_sync
```

Caveats:

* If you have date time fields, or custom fields that will trigger `changed_attributes` this might cause issues when pulling an existing record
* `changed_attributes` doesn't work well with store

## Testing

```ruby
# in spec_helper.rb
require 'netsuite_rails/spec/spec_helper'
```

## Author

* Michael Bianco @iloveitaly