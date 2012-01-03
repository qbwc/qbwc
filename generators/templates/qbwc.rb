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

  #Sync Code
  # This is where you feed requests into the queue.  
  # a request is a 2-tuple consisting of (xml_request, response_proc)
  # Do not put all your business logic here.  Place in Models or Another Structure. 
  
  config.quickbooks_sync = Proc.new do
    parser = Quickbooks::API[QBWC.quickbooks_type]
    requests = []   
    #IE: requests <<  Gdaget.sync_gadgets
    [parser, requests]   
  end
  
  #Will sync instead of a full sync above
  config.quickbooks_sync_specific_records = Proc.new do
    parser = Quickbooks::API[QBWC.quickbooks_type]    
    return [parser, []]    
  end
  
end