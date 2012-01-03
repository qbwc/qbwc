require 'xsd/qname'

# {http://developer.intuit.com/}ArrayOfString
class ArrayOfString < ::Array
end

# {http://developer.intuit.com/}authenticate
#   strUserName - SOAP::SOAPString
#   strPassword - SOAP::SOAPString
class QBWC::Authenticate
  attr_accessor :strUserName
  attr_accessor :strPassword

  def initialize(strUserName = nil, strPassword = nil)
    @strUserName = strUserName
    @strPassword = strPassword
  end
end

# {http://developer.intuit.com/}authenticateResponse
#   authenticateResult - ArrayOfString
class QBWC::AuthenticateResponse
  attr_accessor :authenticateResult

  def initialize(authenticateResult = nil)
    @authenticateResult = authenticateResult
  end
end

# {http://developer.intuit.com/}serverVersion
#   strVersion - SOAP::SOAPString
class QBWC::ServerVersion
  attr_accessor :strVersion

  def initialize(strVersion = nil)
    @strVersion = strVersion
  end
end

# {http://developer.intuit.com/}serverVersionResponse
#   serverVersionResult - SOAP::SOAPString
class QBWC::ServerVersionResponse
  attr_accessor :serverVersionResult

  def initialize(serverVersionResult = nil)
    @serverVersionResult = serverVersionResult
  end
end

# {http://developer.intuit.com/}clientVersion
#   strVersion - SOAP::SOAPString
class QBWC::ClientVersion
  attr_accessor :strVersion

  def initialize(strVersion = nil)
    @strVersion = strVersion
  end
end

# {http://developer.intuit.com/}clientVersionResponse
#   clientVersionResult - SOAP::SOAPString
class QBWC::ClientVersionResponse
  attr_accessor :clientVersionResult

  def initialize(clientVersionResult = nil)
    @clientVersionResult = clientVersionResult
  end
end

# {http://developer.intuit.com/}sendRequestXML
#   ticket - SOAP::SOAPString
#   strHCPResponse - SOAP::SOAPString
#   strCompanyFileName - SOAP::SOAPString
#   qbXMLCountry - SOAP::SOAPString
#   qbXMLMajorVers - SOAP::SOAPInt
#   qbXMLMinorVers - SOAP::SOAPInt
class QBWC::SendRequestXML
  attr_accessor :ticket
  attr_accessor :strHCPResponse
  attr_accessor :strCompanyFileName
  attr_accessor :qbXMLCountry
  attr_accessor :qbXMLMajorVers
  attr_accessor :qbXMLMinorVers

  def initialize(ticket = nil, strHCPResponse = nil, strCompanyFileName = nil, qbXMLCountry = nil, qbXMLMajorVers = nil, qbXMLMinorVers = nil)
    @ticket = ticket
    @strHCPResponse = strHCPResponse
    @strCompanyFileName = strCompanyFileName
    @qbXMLCountry = qbXMLCountry
    @qbXMLMajorVers = qbXMLMajorVers
    @qbXMLMinorVers = qbXMLMinorVers
  end
end

# {http://developer.intuit.com/}sendRequestXMLResponse
#   sendRequestXMLResult - SOAP::SOAPString
class QBWC::SendRequestXMLResponse
  attr_accessor :sendRequestXMLResult

  def initialize(sendRequestXMLResult = nil)
    @sendRequestXMLResult = sendRequestXMLResult
  end
end

# {http://developer.intuit.com/}receiveResponseXML
#   ticket - SOAP::SOAPString
#   response - SOAP::SOAPString
#   hresult - SOAP::SOAPString
#   message - SOAP::SOAPString
class QBWC::ReceiveResponseXML
  attr_accessor :ticket
  attr_accessor :response
  attr_accessor :hresult
  attr_accessor :message

  def initialize(ticket = nil, response = nil, hresult = nil, message = nil)
    @ticket = ticket
    @response = response
    @hresult = hresult
    @message = message
  end
end

# {http://developer.intuit.com/}receiveResponseXMLResponse
#   receiveResponseXMLResult - SOAP::SOAPInt
class QBWC::ReceiveResponseXMLResponse
  attr_accessor :receiveResponseXMLResult

  def initialize(receiveResponseXMLResult = nil)
    @receiveResponseXMLResult = receiveResponseXMLResult
  end
end

# {http://developer.intuit.com/}connectionError
#   ticket - SOAP::SOAPString
#   hresult - SOAP::SOAPString
#   message - SOAP::SOAPString
class QBWC::ConnectionError
  attr_accessor :ticket
  attr_accessor :hresult
  attr_accessor :message

  def initialize(ticket = nil, hresult = nil, message = nil)
    @ticket = ticket
    @hresult = hresult
    @message = message
  end
end

# {http://developer.intuit.com/}connectionErrorResponse
#   connectionErrorResult - SOAP::SOAPString
class QBWC::ConnectionErrorResponse
  attr_accessor :connectionErrorResult

  def initialize(connectionErrorResult = nil)
    @connectionErrorResult = connectionErrorResult
  end
end

# {http://developer.intuit.com/}getLastError
#   ticket - SOAP::SOAPString
class QBWC::GetLastError
  attr_accessor :ticket

  def initialize(ticket = nil)
    @ticket = ticket
  end
end

# {http://developer.intuit.com/}getLastErrorResponse
#   getLastErrorResult - SOAP::SOAPString
class QBWC::GetLastErrorResponse
  attr_accessor :getLastErrorResult

  def initialize(getLastErrorResult = nil)
    @getLastErrorResult = getLastErrorResult
  end
end

# {http://developer.intuit.com/}closeConnection
#   ticket - SOAP::SOAPString
class QBWC::CloseConnection
  attr_accessor :ticket

  def initialize(ticket = nil)
    @ticket = ticket
  end
end

# {http://developer.intuit.com/}closeConnectionResponse
#   closeConnectionResult - SOAP::SOAPString
class QBWC::CloseConnectionResponse
  attr_accessor :closeConnectionResult

  def initialize(closeConnectionResult = nil)
    @closeConnectionResult = closeConnectionResult
  end
end
