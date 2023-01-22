#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'pry', require: true
  gem 'minitest'
  gem 'rubocop'
end

require 'minitest/autorun'

module AASM
  class Configuration
    module DSL
      class Event < Array
        attr_reader :name

        def initialize(name)
          @name = name
        end

        def transitions(from:, to:)
          self << [from, to]
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
        @current_state = state
      end

      events.each do |(_name, event)|
        klass.define_method(:"#{event.name}!") do
          transitions = event.select { |(from, _)| from == current_state }
          _, to = transitions.first
          return current_state unless to

          set_current_state to
        end
      end
    end

    def initial_state
      states.find { |(_name, opts)| opts[:initial] }.first
    end
  end

  module ClassMethods
    def aasm(&block)
      config = Configuration.new(self)
      config.instance_eval(&block)
      config.configure!
    end
  end

  def self.included(klass)
    klass.extend ClassMethods
  end
end

describe AASM do
  class Job
    include AASM

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

  before do
    @subject = Job.new
  end

  describe '#states' do
    it 'returns array of declared states' do
      _(@subject.states).must_equal %i[creating running finished]
    end
  end

  describe '#current_state' do
    it 'returns current state' do
      _(@subject.current_state).must_equal :creating
    end
  end

  describe '#<event>!' do
    it 'change changes matching from #current_state' do
      _(@subject.work_succeeded!).must_equal :running
      _(@subject.work_succeeded!).must_equal :finished
      _(@subject.work_succeeded!).must_equal :finished
    end
  end
end
