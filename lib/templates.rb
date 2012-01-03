class QBWC::Templates

  def self.[](template)
    self.send(template)
  end

  def self.quickbooks_sync_specific_records
    parser = Quickbooks::API[QBWC.quickbooks_type]
    [parser, []]
  end

  def self.quickbooks_sync
    parser = Quickbooks::API[QBWC.quickbooks_type]
    import_requests, export_requests, export_objs = [], [], []

    import_requests << qb.generate_import_query(Member)
    import_requests << qb.generate_import_query(Vendor)
    import_requests << qb.generate_import_query(Department)
    import_requests << qb.generate_import_query(Product)
    import_requests << qb.generate_import_query(Order)
    import_requests << qb.generate_import_query(Receipt)

    export_requests += qb.generate_export_queries(Member)
    export_requests += qb.generate_export_queries(Vendor)
    export_requests += qb.generate_export_queries(Department)
    export_requests += qb.generate_export_queries(Product)
    export_requests += qb.generate_export_queries(Order)
    export_requests += qb.generate_export_queries(Receipt)
    
    [parser, import_requests + export_requests]
  end

end
