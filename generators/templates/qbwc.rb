QBWC.setup do |config|
  
  #Currently Only supported for single logins. 
  config.qbwc_username = "foo"
  config.qbwc_password = "bar"
  
  #Path to Company File (blank for open or named path or function etc..)
  config.quickbooks_company_file_path = ""
  
  #Minimum Quickbooks Version Required for use in QBXML Requests
  config.quickbooks_min_version = 7.0
  
  #Quickbooks Type (either :qb or :qbpos)
  config.quickbooks_type = :qb
  
  #Quickbooks Support URL provided in QWC File
  config.quickbooks_support_site_url = "localhost:3000"
  
  #Quickbooks Owner ID provided in QWC File
  config.quickbooks_owner_id = '{57F3B9B1-86F1-4fcc-B1EE-566DE1813D20}'
  
end