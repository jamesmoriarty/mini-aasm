# frozen_string_literal: true

require "bundler/gem_tasks"

# Test

require "rake/testtask"

Rake::TestTask.new do |task|
  task.libs << "test" # require File.expand_path('test/test_helper', File.dirname(__FILE__))
  task.pattern = "test/*_test.rb"
end

# Lint

require "rubocop/rake_task"

RuboCop::RakeTask.new do |task|
  task.requires << "rubocop-rake"
  task.requires << "rubocop-minitest"
end

# Default

task default: %i[test rubocop]
