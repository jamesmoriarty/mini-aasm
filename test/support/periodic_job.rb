# frozen_string_literal: true

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
      transitions from: %i[waiting executing], to: :terminated
    end
  end

  def work
    send("work_#{current_state}")
  end

  private

  def work_executing
    # ...
    work_succeeded!
  end

  def work_waiting
    # ...
    work_succeeded!
  end
end
