require "bundler/gem_tasks"
require 'appraisal'

Bundler::GemHelper.install_tasks

require 'rake/testtask'
Rake::TestTask.new do |t|
  t.pattern = 'test/**/*_test.rb'
end

task :default => :all

task :all do |_t|
    exec('bundle exec appraisal install && bundle exec rake appraisal test')
end
