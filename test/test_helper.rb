# frozen_string_literal: true

require "pry"

require "minitest"
require "minitest/autorun"
require "minitest/reporters"

Minitest::Reporters.use!
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

require "mini-aasm"

require "support/transmission_job"
