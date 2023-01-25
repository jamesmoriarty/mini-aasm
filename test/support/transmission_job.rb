# frozen_string_literal: true

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

  def initialize(hold: true)
    @hold = hold
  end

  def work
    send("work_#{current_state}")
  end

  private

  def work_waiting_confirmation
    # ...
    work_succeeded!
  rescue StandardError
    work_failed!
  end

  def work_transmitting
    # ...
    work_succeeded!
  end

  def hold?
    !!@hold
  end
end
