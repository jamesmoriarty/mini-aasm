#!/usr/bin/env ruby

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'pry', require: true
  gem 'minitest'
end

require "minitest/autorun"

module AASM
  class Configuration
    attr_reader :klass, :states

    def initialize(klass)
      @klass = klass
      @states = {}
    end

    def state(name, opts = {})
      states[name] = opts
    end

    def event(name)

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
    end

    def initial_state
      states.find { |(name, opts)| opts[:initial] }.first
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
  
    describe "#states" do
      it "returns array of declared states" do
        _(@subject.states).must_equal [:creating, :running, :finished]
      end
    end
  
    describe "#current_state" do
      it "returns current state" do
        _(@subject.current_state).must_equal :creating
      end
    end

    describe "#event" do
      it "defines event method" do
        _(@subject.work_succeeded!).must_equal true
      end
    end
  end