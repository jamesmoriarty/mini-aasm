# frozen_string_literal: true

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
  end

  def initialize(ready: true)
    @ready = ready
  end

  def work
    send("work_#{current_state}")
  end

  private

  def work_executing
    # ...
    work_succeeded!
  rescue StandardError
    work_failed!
  end

  def work_waiting
    # ...
    work_succeeded!
  end

  def ready?
    !!@ready
  end
end
