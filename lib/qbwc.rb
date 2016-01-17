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

  # Credentials to be entered in QuickBooks Web Connector.
  mattr_accessor :username
  @@username = nil
  mattr_accessor :password
  @@password = nil

  # Path to QuickBooks company file on the client. Empty string to use whatever file is open when the connector runs.
  mattr_accessor :company_file_path 
  @@company_file_path = ""

  # Instead of using hard coded username, password, and path, use a proc
  # to determine who has access to what. Useful for multiple users or
  # multiple company files.
  mattr_accessor :authenticator
  @@authenticator = nil

  # QBXML version to use. Check the "Implementation" column in the QuickBooks Onscreen Reference to see which fields are supported in which versions. Newer versions of QuickBooks are backwards compatible with older QBXML versions.
  mattr_accessor :min_version
  @@min_version = "3.0"

  # Quickbooks type (either :qb or :qbpos).
  mattr_reader :api
  @@api = :qb

  # Storage module. Only :active_record is currently supported.
  mattr_accessor :storage
  @@storage = :active_record

  # Support URL shown in QuickBooks Web Connector. nil will use root path of the app.
  mattr_accessor :support_site_url
  @@support_site_url = nil

  # Unique user GUID. If you want access by multiple users to the same file, you will need to modify this in the generated QWC file.
  mattr_accessor :owner_id
  @@owner_id = '{57F3B9B1-86F1-4fcc-B1EE-566DE1813D20}'

  # How often to run web service (in minutes) or nil to only run manually.
  mattr_accessor :minutes_to_run
  @@minutes_to_run = nil

  # Code to execute after each session is authenticated
  mattr_accessor :session_initializer
  @@session_initializer = nil

  # Code to execute after each session has completed all jobs without errors
  mattr_accessor :session_complete_success
  @@session_complete_success = nil

  # In the event of an error running requests, :stop all work or :continue with the next request?
  mattr_reader :on_error
  @@on_error = 'stopOnError'

  # Logger to use.
  mattr_accessor :logger
  @@logger = Rails.logger
  
  # Some log lines contain sensitive information
  mattr_accessor :log_requests_and_responses
  @@log_requests_and_responses = Rails.env == 'production' ? false : true

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

    def delete_job(object_or_name)
      name = (object_or_name.is_a?(Job) ? object_or_name.name : object_or_name)
      storage_module::Job.delete_job_with_name(name)
    end

    def pending_jobs(company, session = QBWC::Session.get)
      js = jobs
      QBWC.logger.info "#{js.length} jobs exist, checking for pending jobs for company '#{company}'."
      storage_module::Job.sort_in_time_order(js.select {|job| job.company == company && job.pending?(session)})
    end
    
    def set_session_initializer(&block)
      @@session_initializer = block
      self
    end

    def set_session_complete_success(&block)
      @@session_complete_success = block
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
    end

    def parser
      @@parser ||= Qbxml.new(api, min_version)
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
