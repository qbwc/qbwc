 
class QBWC::QBWebConnectorSvcSoap
  # SYNOPSIS
  #   serverVersion(parameters)
  #
  # ARGS
  #   parameters      ServerVersion - {http://developer.intuit.com/}serverVersion
  #
  # RETURNS
  #   parameters      ServerVersionResponse - {http://developer.intuit.com/}serverVersionResponse
  #
  def serverVersion(parameters)
    #p parameters
    QBWC::ServerVersionResponse.new(nil)
  end

  # SYNOPSIS
  #   clientVersion(parameters)
  #
  # ARGS
  #   parameters      ClientVersion - {http://developer.intuit.com/}clientVersion
  #
  # RETURNS
  #   parameters      ClientVersionResponse - {http://developer.intuit.com/}clientVersionResponse
  #
  def clientVersion(parameters)
    #p parameters
    QBWC::ClientVersionResponse.new(nil)
  end

  # SYNOPSIS
  #   authenticate(parameters)
  #
  # ARGS
  #   parameters      Authenticate - {http://developer.intuit.com/}authenticate
  #
  # RETURNS
  #   parameters      AuthenticateResponse - {http://developer.intuit.com/}authenticateResponse
  #
  def authenticate(parameters)
    #p parameters                               
    QBWC::AuthenticateResponse.new([QBWC.username, QBWC.company_file_path]) #path to company file
  end

  # SYNOPSIS
  #   sendRequestXML(parameters)
  #
  # ARGS
  #   parameters      SendRequestXML - {http://developer.intuit.com/}sendRequestXML
  #
  # RETURNS
  #   parameters      SendRequestXMLResponse - {http://developer.intuit.com/}sendRequestXMLResponse
  #

  def sendRequestXML(parameters)
    qbwc_session = QBWC::Session.new_or_unfinished
    next_request = qbwc_session.next
    QBWC::SendRequestXMLResponse.new( next_request ? wrap_in_version(next_request.request) : '') 
  end

  # SYNOPSIS
  #   receiveResponseXML(parameters)
  #
  # ARGS
  #   parameters      ReceiveResponseXML - {http://developer.intuit.com/}receiveResponseXML
  #
  # RETURNS
  #   parameters      ReceiveResponseXMLResponse - {http://developer.intuit.com/}receiveResponseXMLResponse
  #
  def receiveResponseXML(response)
    qbwc_session = QBWC::Session.new_or_unfinished
    qbwc_session.response = response.response
    QBWC::ReceiveResponseXMLResponse.new(qbwc_session.progress)
  end

  # SYNOPSIS
  #   connectionError(parameters)
  #
  # ARGS
  #   parameters      ConnectionError - {http://developer.intuit.com/}connectionError
  #
  # RETURNS
  #   parameters      ConnectionErrorResponse - {http://developer.intuit.com/}connectionErrorResponse
  #
  def connectionError(parameters)
    #p [parameters]
    raise NotImplementedError.new
  end

  # SYNOPSIS
  #   getLastError(parameters)
  #
  # ARGS
  #   parameters      GetLastError - {http://developer.intuit.com/}getLastError
  #
  # RETURNS
  #   parameters      GetLastErrorResponse - {http://developer.intuit.com/}getLastErrorResponse
  #
  def getLastError(parameters)
    #p [parameters]
    QBWC::GetLastErrorResponse.new(nil)
  end

  # SYNOPSIS
  #   closeConnection(parameters)
  #
  # ARGS
  #   parameters      CloseConnection - {http://developer.intuit.com/}closeConnection
  #
  # RETURNS
  #   parameters      CloseConnectionResponse - {http://developer.intuit.com/}closeConnectionResponse
  #
  def closeConnection(parameters)
    #p [parameters]
    qbwc_session = QBWC::Session.session
    if qbwc_session && qbwc_session.finished?
      qbwc_session.current_request.process_response unless qbwc_session.current_request.blank?
    end
    QBWC::CloseConnectionResponse.new('OK')
  end

private

  # wraps xml in version header
  def wrap_in_version(xml_rq)
    if QBWC.api == :qbpos
      %Q( <?qbposxml version="#{QBWC.min_version}"?> ) + xml_rq
    else
      %Q( <?qbxml version="#{QBWC.min_version}"?> ) + xml_rq
    end
  end

end
