#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'pry', require: true
  gem 'minitest'
  gem 'minitest-reporters'
  gem 'rubocop'
end

module MiniAASM
  class InvalidTransition < RuntimeError; end
  class UndefinedState < RuntimeError; end

  class Configuration
    module DSL
      module ClassMethods
        def aasm(&block)
          config = Configuration.new(self)
          config.instance_eval(&block)
          config.configure!
        end
      end

      class Event < Array
        attr_reader :name

        def initialize(name)
          @name = name
        end

        def transitions(from:, to:)
          self << [[from].flatten, to]
        end
      end

      def state(name, opts = {})
        states[name] = opts
      end

      def event(name, &block)
        event = Event.new(name)
        event.instance_eval(&block)
        events[name] = event
      end
    end

    include DSL

    attr_reader :klass, :states, :events

    def initialize(klass)
      @klass = klass
      @states = {}
      @events = {}
    end

    def configure!
      _aasm = self

      klass.define_method(:_aasm) { _aasm }

      klass.define_method(:states) do
        _aasm.states.keys
      end

      klass.define_method(:current_state) do
        @current_state ||= _aasm.initial_state
      end

      klass.define_method(:set_current_state) do |state|
        raise UndefinedState unless states.include?(state)

        @current_state = state
      end

      events.each do |(name, event)|
        klass.define_method(:"#{name}!") do
          transitions = event.select { |(from_states, _)| from_states.include?(current_state) }
          _, to_state = transitions.first

          raise InvalidTransition unless to_state

          set_current_state to_state
        end
      end
    end

    def initial_state
      states.find { |(_name, opts)| opts[:initial] }.first
    end
  end

  def self.included(klass)
    klass.extend Configuration::DSL::ClassMethods
  end
end

# Tests

require 'minitest/autorun'
require 'minitest/reporters'

Minitest::Reporters.use!
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

describe MiniAASM do
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

  before do
    @subject = PeriodicJob.new
  end

  describe '#states' do
    it 'returns states' do
      _(@subject.states).must_equal %i[waiting executing terminated]
    end
  end

  describe '#current_state' do
    it 'returns state' do
      _(@subject.current_state).must_equal :waiting
    end
  end

  describe '#set_current_state' do
    it 'returns new state' do
      _(@subject.set_current_state(:terminated)).must_equal :terminated
    end

    it 'raises exception with invalid state' do
      assert_raises(MiniAASM::UndefinedState) { @subject.set_current_state(:cooked) }
    end
  end

  describe '.aasm' do
    describe '.event' do
      describe '.transistions' do
        it 'change' do
          _(@subject.work_succeeded!).must_equal :executing
        end

        it 'multiple matching' do
          _(@subject.work_succeeded!).must_equal :executing
          _(@subject.work_failed!).must_equal :terminated
        end

        it 'persist' do
          _(@subject.work_succeeded!).must_equal :executing
          _(@subject.work_succeeded!).must_equal :waiting
        end

        it 'raises exception without matching' do
          _(@subject.set_current_state(:terminated)).must_equal :terminated
          assert_raises(MiniAASM::InvalidTransition) { @subject.work_succeeded! }
        end
      end
    end
  end
end
