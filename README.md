# NetSuite Rails

**Note:** Documentation is horrible... look at the code for details.

Build custom rails application that sync to NetSuite.

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
NetSuiteRails.configure do
	
end
```

## Usage

modes: :read, :read_write, :aggressive

When using a proc in a NS mapping, you are responsible for setting local and remote values

for pushing tasks to DJ https://github.com/collectiveidea/delayed_job/wiki/Rake-Task-as-a-Delayed-Job

### Syncing

```bash
rake netsuite:sync

rake netsuite:fresh_sync
```

## Testing

```ruby
# in spec_helper.rb
require 'netsuite_rails/spec/spec_helper'
```

## Author

* Michael Bianco @iloveitaly