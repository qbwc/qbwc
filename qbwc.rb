#TODO: replace with ruby 1.9 external iterator

module QBWC
  
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
  
  
  # Default way to setup Quickbooks Web Connector (QBWC). Run rails generate qbwc:install
  # to create a fresh initializer with all configuration values.
  def self.setup
    yield self
  end
  
end

ROOT_PATH    = File.dirname(__FILE__)
LIB_PATH     = File.join(ROOT_PATH, 'lib')
LIB_FILES    = %w( soap_wrapper/default
                   soap_wrapper/defaultMappingRegistry 
                   soap_wrapper/defaultServant 
                   soap_wrapper/QBWebConnectorSvc 
                   interface templates session )
                   
LIB_FILES.each { |f| require File.join(LIB_PATH, f) }
