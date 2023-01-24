# MiniAASM

A State Machine library intended to be compatible with lightweight implementations of the Ruby language using 100LOC and only standard libraries.

## Usage

```ruby
class PeriodicJob
  include MiniAASM

  aasm do
    state :waiting, initial: true
    state :executing
    state :terminated

    event :work_succeeded do
      transitions from: :executing, to: :waiting
      transitions from: :waiting, to: :executing, guard: %i[ready?]
    end

    event :work_failed do
      transitions from: %i[waiting executing], to: :terminated
    end

    # ...
  end
end
```

```
> db = DBInstance.new
=> #<DBInstance:0x000055a4a77c52f8>
> db.current_state
=> :creating
> db.created!
=> :wait_running
> db.detect_online!
=> :running
> db.detect_online!
=> MiniAASM::InvalidTransition (MiniAASM::InvalidTransition)
```

## Best Practice

1. The state machine should be trying to converge an eventually consistent end state which looks like a status.
2. States should be separated into atomic units of work.
3. State transitions should be invoked in an idempotent way.
  
## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mini-aasm'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install mini-aasm

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/mini-aasm.
