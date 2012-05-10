require 'qbwc/version'
require 'quickbooks'

module QBWC
  #QBWC login credentials
  mattr_accessor :username
  @@username = 'foo'
  mattr_accessor :password
  @@password = 'bar'
  
  #Path to Company File 
  mattr_accessor :quickbooks_company_file_path 
  @@quickbooks_company_file_path = "" #blank for open or named path or function etc..
  
  #Minimum Quickbooks Version Required for use in QBXML Requests
  mattr_accessor :quickbooks_min_version
  @@quickbooks_min_version = 3.0
  
  #Quickbooks Support URL provided in QWC File
  mattr_accessor :quickbooks_support_site_url
  @@quickbooks_support_site_url = 'http://qb_support.lumber.com'
  
  #Quickbooks Owner ID provided in QWC File
  mattr_accessor :quickbooks_owner_id
  @@quickbooks_owner_id = '{57F3B9B1-86F1-4fcc-B1EE-566DE1813D20}'
  
  #Job definitions
  mattr_reader :jobs
  @@jobs = {}
  
  #Enable any or all of the defined jobs
  mattr_accessor :enabled_jobs
  @@enabled_jobs = []

  # Do processing after session termination
  # Enabling this option will speed up qbwc session time but will necessarily eat
  # up more memory since every response must be stored until it is processed. 
  mattr_accessor :delayed_processing
  @@delayed_processing = false

  #Quickbooks Type (either :qb or :qbpos)
  mattr_reader :quickbooks_type
  @@quickbooks_type = :qb
  @@parser = ::Quickbooks::API[quickbooks_type]
  
class << self

  def add_job(name, requests, response_proc)
    @@jobs[name] = Job.new_static(name, requests, response_proc)
  end

  def add_dynamic_job(name, request_generator, response_proc)
    @@jobs[name] = Job.new_dynamic(name, request_generator, response_proc)
  end

  def quickbooks_type=(qb_type)
    raise 'Quickbooks type must be :qb or :qbpos' unless [:qb, :qbpos].include?(qb_type)
    @@quickbooks_type = qb_type
    @@parser = ::Quickbooks::API[qb_type]
  end

  # Default way to setup Quickbooks Web Connector (QBWC). Run rails generate qbwc:install
  # to create a fresh initializer with all configuration values.
  def configure
    yield self
  end

end
  
end

#Todo Move this to Autolaod
require 'qbwc/soap_wrapper/default'
require 'qbwc/soap_wrapper/defaultMappingRegistry'
require 'qbwc/soap_wrapper/defaultServant'
require 'qbwc/soap_wrapper/QBWebConnectorSvc'
require 'qbwc/soap_wrapper'
require 'qbwc/session'
require 'qbwc/request'
require 'qbwc/job'
