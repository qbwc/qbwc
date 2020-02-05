# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "qbwc/version"

Gem::Specification.new do |s|
  s.name        = "qbwc"
  s.version     = QBWC::VERSION
  s.authors     = ["Alex Skryl", "Russell Osborne", "German Garcia", "Jason Barnabe"]
  s.email       = ["rut216@gmail.com", "russell@burningpony.com", "geermc4@gmail.com", "jason.barnabe@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{A Rails interface for Intuit's Quickbooks Web Connector}
  s.description = %q{A Rails interface for Intuit's Quickbooks Web Connector that's OPEN SOURCE!}

  s.rubyforge_project = "qbwc"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.extra_rdoc_files = [
    "README.md"
  ]

  s.required_ruby_version = '>= 2.2.2'

  s.add_dependency "qbxml", [">= 0.3.0"]
  s.add_dependency "wash_out", ['>=0.12.0']
  s.add_dependency 'actionpack', ['>= 5.0.1']

  s.add_development_dependency('webmock')
  s.add_development_dependency('rspec')
  s.add_development_dependency('activerecord')
  s.add_development_dependency('rails', [">= 5.0.1", '< 6.1'])
  s.add_development_dependency('sqlite3')
  s.add_development_dependency('minitest')
  s.add_development_dependency('rake')
  s.add_development_dependency('appraisal')
  s.add_development_dependency('savon')
  s.add_development_dependency('httpi')
  s.add_development_dependency('byebug')
end
