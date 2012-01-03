class QBWC::Templates

  def self.[](template)
    self.send(template)
  end

  def self.quickbooks_sync_specific_records
    QBWC.quickbooks_sync_specific_records.call 
  end

  def self.quickbooks_sync
    QBWC.quickbooks_sync.call
  end

end
