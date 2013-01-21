$:.unshift File.dirname(File.expand_path(__FILE__))
require 'qbwc/version'
require 'quickbooks'

module QBWC

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
  
  # Quickbooks support url provided in qwc file
  mattr_accessor :support_site_url
  @@support_site_url = 'http://google.com'
  
  # Quickbooks owner id provided in qwc file
  mattr_accessor :owner_id
  @@owner_id = '{57F3B9B1-86F1-4fcc-B1EE-566DE1813D20}'
  
  # Job definitions
  mattr_reader :jobs
  @@jobs = {}
  
  mattr_reader :on_error
  @@on_error = 'stopOnError'
  # Do processing after session termination
  # Enabling this option will speed up qbwc session time but will necessarily eat
  # up more memory since every response must be stored until it is processed. 
  mattr_accessor :delayed_processing
  @@delayed_processing = false

  # Quickbooks Type (either :qb or :qbpos)
  mattr_reader :api, :parser
  @@api = :qb #::Quickbooks::API[:qb]
  
  # Check Rails Cache for Parser before boot
  mattr_accessor :warm_boot
  @@warm_boot = false

class << self

  def add_job(name,priority=0, &block)
    @@jobs[name] = Job.new(name, priority, &block)
    @@jobs.sort_by{|queue, job| job.priority }.reverse
  end
  
  def on_error=(reaction)
    raise 'Quickbooks type must be :qb or :qbpos' unless [:stop, :continue].include?(reaction)
    @@on_error = "stopOnError" if reaction == :stop
    @@on_error = "continueOnError" if reaction == :continue
  end
  
  def api=(api)
    raise 'Quickbooks type must be :qb or :qbpos' unless [:qb, :qbpos].include?(api)
    @@api = api
    if @@warm_boot
      ::Rails.logger.warn "using warm boot"
      @@parser = ::Rails.cache.read("qb_api_#{api}") || ::Quickbooks::API[api] 
      ::Rails.cache.write("qb_api_#{api}", @@parser)
    else
      @@parser = ::Quickbooks::API[api] 
    end
  end

  # Allow configuration overrides
  def configure
    yield self
  end


end
  
end

require 'fiber'

#Todo Move this to Autolaod
require 'qbwc/soap_wrapper/default'
require 'qbwc/soap_wrapper/defaultMappingRegistry'
require 'qbwc/soap_wrapper/defaultServant'
require 'qbwc/soap_wrapper/QBWebConnectorSvc'
require 'qbwc/soap_wrapper'
require 'qbwc/session'
require 'qbwc/request'
require 'qbwc/job'
