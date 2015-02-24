QBWC.configure do |c|

  # Credentials to be entered in QuickBooks Web Connector.
  c.username = "foo"
  c.password = "bar"

  # Path to QuickBooks company file on the client. Empty string to use whatever file is open when the connector runs.
  c.company_file_path = ""

  # Instead of using hard coded username, password, and path, use a proc
  # to determine who has access to what. Useful for multiple users or
  # multiple company files.
  # c.authenticator = Proc.new{|username, password|
  #   # qubert can access Oceanic
  #   next "C:\\QuickBooks\\Oceanic.QBW" if username == "qubert" && password == "brittany"
  #   # quimby can access Veridian
  #   next "C:\\QuickBooks\\Veridian.QBW" if username == "quimby" && password == "bethany"
  #   # no one else has access
  #   next nil
  # }

  # Code to execute after each session is authenticated
  # Can be re-assigned by calling QBWC.set_session_initializer
  # c.session_initializer = Proc.new{|session|
  #   puts "New QuickBooks Web Connector session has been established"
  # }

  # QBXML version to use. Check the "Implementation" column in the QuickBooks Onscreen Reference to see which fields are supported in which versions. Newer versions of QuickBooks are backwards compatible with older QBXML versions.
  c.min_version = "7.0"
  
  # Quickbooks type (either :qb or :qbpos).
  c.api = :qb

  # Storage module. Only :active_record is currently supported.
  c.storage = :active_record
  
  # Support URL shown in QuickBooks Web Connector. nil will use root path of the app.
  c.support_site_url = nil
  
  # Unique user GUID. If you want access by multiple users to the same file, you will need to modify this in the generated QWC file.
  c.owner_id = '{57F3B9B1-86F1-4fcc-B1EE-566DE1813D20}'

  # How often to run web service (in minutes) or nil to only run manually.
  c.minutes_to_run = nil

  # In the event of an error running requests, :stop all work or :continue with the next request?
  c.on_error = :stop

  # Logger to use.
  c.logger = Rails.logger

  # Some log lines contain sensitive information
  # (default false on production, true otherwise)
  # c.log_requests_and_responses = false
end
