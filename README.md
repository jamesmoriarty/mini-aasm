# MiniAASM

The [State Machine](https://en.wikipedia.org/wiki/Finite-state_machine) library is intended to be compatibility with [lightweight implementation of the Ruby language](https://github.com/mruby/mruby).


## Example

```ruby
  class Job
    include MiniAASM

    aasm do
      state :creating, initial: true
      state :running
      state :finished
  
      event :work_succeeded do
        transitions from: :creating, to: :running
        transitions from: :running, to: :finished
      end
    end
  end
```

```
> job = Job.new
#=> <Job ...>
> job.current_state
#=> :creating
> job.work_succeeded!
#=> :running
> job.work_succeeded!
#=> :finished
```

## Best Practice

1. Transition work should be idempotent.
   
```ruby

class Job

  #...

  def work
    send('work_' + current_state)
  end

  def work_creating
    return unless current_state == :creating
    return unless created_at.nil?

    # ...

    work_succeeded!
  end
end
```

2. States should be separated into atomic units of work.
   
```ruby
class PeriodicJob
  include MiniAASM

  aasm do
    state :waiting, initial: true
    state :executing
    state :terminated

    event :work_succeeded do
      transitions from: :executing, to: :waiting
      transitions from: :waiting, to: :executing
    end

    event :work_failed do
      transitions from: [:waiting, :executing], to: :terminated
    end
  end
end
```

3. The state machine should be trying to converge a eventually consistent end state which looks like a status.

```ruby
  state :creating, initial: true
  state :running
  state :stopping
  state :starting_instance
  state :wait_running

  event :created do
    transitions from: :creating, to: :wait_running
  end

  event :detect_online do
    transitions from: :wait_running, to: :running
  end

  event :detect_unavailable do
    transitions from: :running, to: :stopping
  end

  event :stopped do
    transitions from: :stopping, to: :starting_instance
  end

  event :started do
    transitions from: :starting_instance, to: :wait_running
  end
```

## TODO

- [ ] named state machines.

```ruby
aasm(:work) do
  # ...
end
```

- [ ] guard clauses.

```ruby
transitions from: :pending, to: :notifying, guard: :oncall?
```
