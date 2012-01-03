class QBWC::Templates

  def self.[](template)
    self.send(template)
  end

  def self.quickbooks_sync_specific_records
   return QBWC.quickbooks_sync_specific_records.call 
  end

  def self.quickbooks_sync
   return QBWC.quickbooks_sync.call
  end

end
