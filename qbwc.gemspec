# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "qbwc/version"

Gem::Specification.new do |s|
  s.name        = "qbwc"
  s.version     = QBWC::VERSION
  s.authors     = ["Alex Skryl", "Russell Osborne", "German Garcia"]
  s.email       = ["rut216@gmail.com", "russell@burningpony.com", "geermc4@gmail.com"]
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

  s.add_dependency "quickbooks_api", [">= 0.1.6"]
  s.add_dependency "rubyjedi-soap4r", [">= 1.5.8.20100619003610"]
  s.add_development_dependency('guard')
  s.add_development_dependency('guard-rspec')
  s.add_development_dependency('rb-fsevent')
  s.add_development_dependency('webmock')
  s.add_development_dependency('rspec')

end
