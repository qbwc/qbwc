#TODO: replace with ruby 1.9 external iterator
require "qbwc/version"


module QBWC
  
  #Todo Move this to Autolaod
  require 'qbwc/soap_wrapper/default'
  require 'qbwc/soap_wrapper/defaultMappingRegistry'
  require 'qbwc/soap_wrapper/defaultServant'
  require 'qbwc/soap_wrapper/QBWebConnectorSvc'
  require 'qbwc/interface'
  require 'qbwc/templates'
  require 'qbwc/session'
  
  #QBWC login credentials
  mattr_accessor :qbwc_username
  @@qbwc_username = "foo"
  mattr_accessor :qbwc_password
  @@qbwc_password = "bar"
  
  #Path to Company File 
  mattr_accessor :quickbooks_company_file_path 
  @@quickbooks_company_file_path = "" #blank for open or named path or function etc..
  
  #Minimum Quickbooks Version Required for use in QBXML Requests
  mattr_accessor :quickbooks_min_version
  @@quickbooks_min_version = 3.0
  
  #Quickbooks Type (either :qb or :qbpos)
  mattr_accessor :quickbooks_type
  @@quickbooks_min_version = :qb
  
  #Quickbooks Support URL provided in QWC File
  mattr_accessor :quickbooks_support_site_url
  @@quickbooks_support_site_url = "http://qb_support.lumber.com"
  
  #Quickbooks Owner ID provided in QWC File
  mattr_accessor :quickbooks_owner_id
  @@quickbooks_owner_id = '{57F3B9B1-86F1-4fcc-B1EE-566DE1813D20}'
  
  #Block to run on Full Sync
  mattr_accessor :quickbooks_sync
  
  #Block to Run on Single Sync
  mattr_accessor :quickbooks_sync_specific_records

  
  # Default way to setup Quickbooks Web Connector (QBWC). Run rails generate qbwc:install
  # to create a fresh initializer with all configuration values.
  def self.setup
    yield self
  end
  
end
