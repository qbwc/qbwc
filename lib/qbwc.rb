require 'qbwc/railtie'
require 'qbxml'

module QBWC
  autoload :ActiveRecord, 'qbwc/active_record'
  autoload :Controller, 'qbwc/controller'
  autoload :Version, 'qbwc/version'
  autoload :Job, 'qbwc/job'
  autoload :Session, 'qbwc/session'
  autoload :Request, 'qbwc/request'

  # Web connector login credentials
  mattr_accessor :username
  @@username = 'foo'
  mattr_accessor :password
  @@password = 'bar'
  
  # Full path to pompany file 
  mattr_accessor :company_file_path 
  @@company_file_path = ""
  
  # Minimum quickbooks version required for use in qbxml requests
  mattr_accessor :min_version
  @@min_version = 3.0
  
  # Quickbooks support url provided in qwc file, defaults to root_url
  mattr_accessor :support_site_url
  @@support_site_url = nil
  
  # Quickbooks owner id provided in qwc file
  mattr_accessor :owner_id
  @@owner_id = '{57F3B9B1-86F1-4fcc-B1EE-566DE1813D20}'
  
  # How often to run web service (in minutes)
  mattr_accessor :minutes_to_run
  @@minutes_to_run = 5
  
  # Job definitions
  mattr_reader :jobs
  @@jobs = {}
  
  mattr_reader :on_error
  @@on_error = 'stopOnError'

  # Quickbooks Type (either :qb or :qbpos)
  mattr_reader :api, :parser
  @@api = :qb

  # Storage module
  mattr_reader :storage
  @@storage = :active_record
  
  class << self

    def storage_module
      const_get storage.to_s.camelize
    end
    
    def add_job(name, company = nil, &block)
      @@jobs[name.to_sym] = storage_module::Job.new(name, company, &block)
    end

    def pending_jobs(company)
      @@jobs.values.select {|job| job.company == company && job.pending?}
    end
    
    def on_error=(reaction)
      raise 'Quickbooks type must be :qb or :qbpos' unless [:stop, :continue].include?(reaction)
      @@on_error = "stopOnError" if reaction == :stop
      @@on_error = "continueOnError" if reaction == :continue
    end
    
    def api=(api)
      raise 'Quickbooks type must be :qb or :qbpos' unless [:qb, :qbpos].include?(api)
      @@api = api
      @@parser = Qbxml.new(api) 
    end

    # Allow configuration overrides
    def configure
      yield self
    end

  end
  
end

require 'fiber'
