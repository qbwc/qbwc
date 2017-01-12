require "bundler/gem_tasks"

Bundler::GemHelper.install_tasks

require 'rake/testtask'
Rake::TestTask.new do |t|
  t.pattern = 'test/**/*_test.rb'
end
task :default => :test

# TODO make backfiller for requests[nil] --> default_requests on qbwc_jobs
