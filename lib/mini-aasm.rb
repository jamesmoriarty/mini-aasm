# frozen_string_literal: true

require "mini_aasm/version"

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

      class StateTransitions < Array
        attr_reader :name

        def initialize(name)
          @name = name

          super()
        end

        def transitions(from:, to:)
          self << [[from].flatten, to]
        end
      end

      def state(name, opts = {})
        states[name] = opts
      end

      def event(name, &block)
        event = StateTransitions.new(name)
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
