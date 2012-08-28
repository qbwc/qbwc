require 'soap/rpc/standaloneServer'

class Qbwc::SoapWrapper
  include Qbwc
  private_class_method :new

  def self.initialize_singleton
    @router = ::SOAP::RPC::Router.new('QBWebConnectorSvcSoap')
    @router.mapping_registry = DefaultMappingRegistry::EncodedRegistry
    @router.literal_mapping_registry = DefaultMappingRegistry::LiteralRegistry
    @conn_data = ::SOAP::StreamHandler::ConnectionData.new

    servant = QBWebConnectorSvcSoap.new
    QBWebConnectorSvcSoap::Methods.each do |definitions|
      opt = definitions.last
      if opt[:request_style] == :document
        @router.add_document_operation(servant, *definitions)
      else
        @router.add_rpc_operation(servant, *definitions)
      end
    end
  end

  def self.route_request(request)
    @conn_data.receive_string = request.raw_post
    @conn_data.receive_contenttype = request.content_type
    @conn_data.soapaction = nil

    @router.external_ces = nil 
    res_data = @router.route(@conn_data) 
    res_data.send_string
  end

  initialize_singleton
end
