require 'soap/mapping'

module QBWC::DefaultMappingRegistry
  include QBWC
  EncodedRegistry = ::SOAP::Mapping::EncodedRegistry.new
  LiteralRegistry = ::SOAP::Mapping::LiteralRegistry.new
  NsDeveloperIntuitCom = "http://developer.intuit.com/"

  EncodedRegistry.register(
    :class => ArrayOfString,
    :schema_type => XSD::QName.new(NsDeveloperIntuitCom, "ArrayOfString"),
    :schema_element => [
      ["string", "SOAP::SOAPString[]", [0, nil]]
    ]
  )

  LiteralRegistry.register(
    :class => ArrayOfString,
    :schema_type => XSD::QName.new(NsDeveloperIntuitCom, "ArrayOfString"),
    :schema_element => [
      ["string", "SOAP::SOAPString[]", [0, nil]]
    ]
  )

  LiteralRegistry.register(
    :class => Authenticate,
    :schema_name => XSD::QName.new(NsDeveloperIntuitCom, "authenticate"),
    :schema_element => [
      ["strUserName", "SOAP::SOAPString", [0, 1]],
      ["strPassword", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => AuthenticateResponse,
    :schema_name => XSD::QName.new(NsDeveloperIntuitCom, "authenticateResponse"),
    :schema_element => [
      ["authenticateResult", "ArrayOfString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => ServerVersion,
    :schema_name => XSD::QName.new(NsDeveloperIntuitCom, "serverVersion"),
    :schema_element => [
      ["strVersion", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => ServerVersionResponse,
    :schema_name => XSD::QName.new(NsDeveloperIntuitCom, "serverVersionResponse"),
    :schema_element => [
      ["serverVersionResult", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => ClientVersion,
    :schema_name => XSD::QName.new(NsDeveloperIntuitCom, "clientVersion"),
    :schema_element => [
      ["strVersion", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => ClientVersionResponse,
    :schema_name => XSD::QName.new(NsDeveloperIntuitCom, "clientVersionResponse"),
    :schema_element => [
      ["clientVersionResult", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => SendRequestXML,
    :schema_name => XSD::QName.new(NsDeveloperIntuitCom, "sendRequestXML"),
    :schema_element => [
      ["ticket", "SOAP::SOAPString", [0, 1]],
      ["strHCPResponse", "SOAP::SOAPString", [0, 1]],
      ["strCompanyFileName", "SOAP::SOAPString", [0, 1]],
      ["qbXMLCountry", "SOAP::SOAPString", [0, 1]],
      ["qbXMLMajorVers", "SOAP::SOAPInt"],
      ["qbXMLMinorVers", "SOAP::SOAPInt"]
    ]
  )

  LiteralRegistry.register(
    :class => SendRequestXMLResponse,
    :schema_name => XSD::QName.new(NsDeveloperIntuitCom, "sendRequestXMLResponse"),
    :schema_element => [
      ["sendRequestXMLResult", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => ReceiveResponseXML,
    :schema_name => XSD::QName.new(NsDeveloperIntuitCom, "receiveResponseXML"),
    :schema_element => [
      ["ticket", "SOAP::SOAPString", [0, 1]],
      ["response", "SOAP::SOAPString", [0, 1]],
      ["hresult", "SOAP::SOAPString", [0, 1]],
      ["message", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => ReceiveResponseXMLResponse,
    :schema_name => XSD::QName.new(NsDeveloperIntuitCom, "receiveResponseXMLResponse"),
    :schema_element => [
      ["receiveResponseXMLResult", "SOAP::SOAPInt"]
    ]
  )

  LiteralRegistry.register(
    :class => ConnectionError,
    :schema_name => XSD::QName.new(NsDeveloperIntuitCom, "connectionError"),
    :schema_element => [
      ["ticket", "SOAP::SOAPString", [0, 1]],
      ["hresult", "SOAP::SOAPString", [0, 1]],
      ["message", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => ConnectionErrorResponse,
    :schema_name => XSD::QName.new(NsDeveloperIntuitCom, "connectionErrorResponse"),
    :schema_element => [
      ["connectionErrorResult", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => GetLastError,
    :schema_name => XSD::QName.new(NsDeveloperIntuitCom, "getLastError"),
    :schema_element => [
      ["ticket", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => GetLastErrorResponse,
    :schema_name => XSD::QName.new(NsDeveloperIntuitCom, "getLastErrorResponse"),
    :schema_element => [
      ["getLastErrorResult", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CloseConnection,
    :schema_name => XSD::QName.new(NsDeveloperIntuitCom, "closeConnection"),
    :schema_element => [
      ["ticket", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CloseConnectionResponse,
    :schema_name => XSD::QName.new(NsDeveloperIntuitCom, "closeConnectionResponse"),
    :schema_element => [
      ["closeConnectionResult", "SOAP::SOAPString", [0, 1]]
    ]
  )
end
