# MiniAASM

![Gem Version][3] ![Gem][1] ![Build Status][2]

A [Finite-state machine](https://en.wikipedia.org/wiki/Finite-state_machine) library intended to be compatible with [lightweight implementations](https://github.com/mruby/mruby) of the Ruby language using 100LOC and only standard libraries. Inspired by [Heroku Postgres State Machines](https://www.citusdata.com/blog/2016/08/12/state-machines-to-run-databases/).

## Usage

```ruby
class TransmissionJob
  include MiniAASM

  aasm do
    state :transmitting, initial: true
    state :waiting_confirmation
    state :terminated

    event :work_succeeded do
      transitions from: :waiting_confirmation, to: :transmitting
      transitions from: :transmitting, to: :waiting_confirmation, guard: %i[hold?]
    end

    event :work_failed do
      transitions from: %i[transmitting waiting_confirmation], to: :terminated
    end
  end

  # ...
end
```

_See [test/support/transmission_job.rb](test/support/transmission_job.rb)._

```ruby
> job = TransmissionJob.new
=> #<TransmissionJob:0x000056134d801450>
>  job.current_state
=> :transmitting
job.work_succeeded!
=> :waiting_confirmation
> job.work_succeeded!
=> :transmitting
> job.work_failed!
=> :terminated
```
  
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

Bug reports and pull requests are welcome on GitHub at https://github.com/jamesmoriarty/mini-aasm.

[1]: https://img.shields.io/gem/dt/mini-aasm
[2]: https://github.com/jamesmoriarty/mini-aasm/workflows/Continuous%20Integration/badge.svg?branch=main
[3]: https://img.shields.io/gem/v/mini-aasm
