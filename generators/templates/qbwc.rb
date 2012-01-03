QBWC.setup do |config|
  
  #Minimum Quickbooks Version Required for use in QBXML Requests
  config.quickbooks_min_version = 3.0
  
  #Quickbooks Type (either :qb or :qbpos)
  config.quickbooks_type = :qb
  
  #Quickbooks Support URL provided in QWC File
  config.quickbooks_support_site_url = "http://qb_support.lumber.com"
  
  #Quickbooks Owner ID provided in QWC File
  config.quickbooks_owner_id = '{57F3B9B1-86F1-4fcc-B1EE-566DE1813D20}'
  
end