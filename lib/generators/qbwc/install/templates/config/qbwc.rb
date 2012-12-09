QBWC.configure do |c|
  
  #Currently Only supported for single logins. 
  c.username = "foo"
  c.password = "bar"
  
  #Path to Company File (blank for open or named path or function etc..)
  c.company_file_path = ""
  
  #Minimum Quickbooks Version Required for use in QBXML Requests
  c.min_version = 7.0
  
  #Quickbooks Type (either :qb or :qbpos)
  c.api = :qb
  
  #Quickbooks Support URL provided in QWC File
  c.support_site_url = "localhost:3000"
  
  #Quickbooks Owner ID provided in QWC File
  c.owner_id = '{57F3B9B1-86F1-4fcc-B1EE-566DE1813D20}'

  # Perform response processing after session termination. Enabling this option
  # will speed up qbwc session time (and potentially fix timeout issues) but
  # will necessarily eat up more memory since every response must be stored
  # until it is processed. 
  c.delayed_processing = false

  # In the event of an error in the communication process do you wish the sync to stop or blaze through
  #
  # Options: 
  # :stop
  # :continue
  c.on_error = :stop

  # Rails Cache Hot Boot  (Check the rails cache for existing API object to speed app boot) 
  # This Feature is Unstable and is Extreme Alpha.  IT is known not to work
  # c.warm_boot = false
  
end
