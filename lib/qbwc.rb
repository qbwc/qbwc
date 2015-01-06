require 'qbwc/railtie'
require 'qbxml'

module QBWC
  autoload :ActiveRecord, 'qbwc/active_record'
  autoload :Controller, 'qbwc/controller'
  autoload :Version, 'qbwc/version'
  autoload :Job, 'qbwc/job'
  autoload :Session, 'qbwc/session'
  autoload :Request, 'qbwc/request'
  autoload :Worker, 'qbwc/worker'

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
  
  mattr_reader :session_initializer
  @@session_initializer = nil

  mattr_reader :on_error
  @@on_error = 'stopOnError'

  # Quickbooks Type (either :qb or :qbpos)
  mattr_reader :api, :parser
  @@api = :qb

  # Storage module
  mattr_accessor :storage
  @@storage = :active_record

  mattr_accessor :logger
  @@logger = Rails.logger
  
  class << self

    def storage_module
      const_get storage.to_s.camelize
    end

    def jobs
      storage_module::Job.list_jobs
    end

    def add_job(name, enabled = true, company = nil, klass = QBWC::Worker, requests = nil, data = nil)
      storage_module::Job.add_job(name, enabled, company, klass, requests, data)
    end

    def get_job(name)
      storage_module::Job.find_job_with_name(name)
    end

    def delete_job(name)
      storage_module::Job.delete_job_with_name(name)
    end

    def pending_jobs(company)
      js = jobs
      QBWC.logger.info "#{js.length} jobs exist, checking for pending jobs for company '#{company}'."
      storage_module::Job.sort_in_time_order(js.select {|job| job.company == company && job.pending?})
    end
    
    def set_session_initializer(&block)
      @@session_initializer = block
      self
    end

    def on_error=(reaction)
      raise 'Quickbooks on_error must be :stop or :continue' unless [:stop, :continue].include?(reaction)
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

    def clear_jobs
      storage_module::Job.clear_jobs
    end

  end
  
end
