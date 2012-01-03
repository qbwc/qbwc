module QBWC
class QBWebConnectorSvcSoap
  Methods = [
    [ "http://developer.intuit.com/serverVersion",
      "serverVersion",
      [ ["in", "parameters", ["::SOAP::SOAPElement", "http://developer.intuit.com/", "serverVersion"]],
        ["out", "parameters", ["::SOAP::SOAPElement", "http://developer.intuit.com/", "serverVersionResponse"]] ],
      { :request_style =>  :document, :request_use =>  :literal,
        :response_style => :document, :response_use => :literal,
        :faults => {} }
    ],
    [ "http://developer.intuit.com/clientVersion",
      "clientVersion",
      [ ["in", "parameters", ["::SOAP::SOAPElement", "http://developer.intuit.com/", "clientVersion"]],
        ["out", "parameters", ["::SOAP::SOAPElement", "http://developer.intuit.com/", "clientVersionResponse"]] ],
      { :request_style =>  :document, :request_use =>  :literal,
        :response_style => :document, :response_use => :literal,
        :faults => {} }
    ],
    [ "http://developer.intuit.com/authenticate",
      "authenticate",
      [ ["in", "parameters", ["::SOAP::SOAPElement", "http://developer.intuit.com/", "authenticate"]],
        ["out", "parameters", ["::SOAP::SOAPElement", "http://developer.intuit.com/", "authenticateResponse"]] ],
      { :request_style =>  :document, :request_use =>  :literal,
        :response_style => :document, :response_use => :literal,
        :faults => {} }
    ],
    [ "http://developer.intuit.com/sendRequestXML",
      "sendRequestXML",
      [ ["in", "parameters", ["::SOAP::SOAPElement", "http://developer.intuit.com/", "sendRequestXML"]],
        ["out", "parameters", ["::SOAP::SOAPElement", "http://developer.intuit.com/", "sendRequestXMLResponse"]] ],
      { :request_style =>  :document, :request_use =>  :literal,
        :response_style => :document, :response_use => :literal,
        :faults => {} }
    ],
    [ "http://developer.intuit.com/receiveResponseXML",
      "receiveResponseXML",
      [ ["in", "parameters", ["::SOAP::SOAPElement", "http://developer.intuit.com/", "receiveResponseXML"]],
        ["out", "parameters", ["::SOAP::SOAPElement", "http://developer.intuit.com/", "receiveResponseXMLResponse"]] ],
      { :request_style =>  :document, :request_use =>  :literal,
        :response_style => :document, :response_use => :literal,
        :faults => {} }
    ],
    [ "http://developer.intuit.com/connectionError",
      "connectionError",
      [ ["in", "parameters", ["::SOAP::SOAPElement", "http://developer.intuit.com/", "connectionError"]],
        ["out", "parameters", ["::SOAP::SOAPElement", "http://developer.intuit.com/", "connectionErrorResponse"]] ],
      { :request_style =>  :document, :request_use =>  :literal,
        :response_style => :document, :response_use => :literal,
        :faults => {} }
    ],
    [ "http://developer.intuit.com/getLastError",
      "getLastError",
      [ ["in", "parameters", ["::SOAP::SOAPElement", "http://developer.intuit.com/", "getLastError"]],
        ["out", "parameters", ["::SOAP::SOAPElement", "http://developer.intuit.com/", "getLastErrorResponse"]] ],
      { :request_style =>  :document, :request_use =>  :literal,
        :response_style => :document, :response_use => :literal,
        :faults => {} }
    ],
    [ "http://developer.intuit.com/closeConnection",
      "closeConnection",
      [ ["in", "parameters", ["::SOAP::SOAPElement", "http://developer.intuit.com/", "closeConnection"]],
        ["out", "parameters", ["::SOAP::SOAPElement", "http://developer.intuit.com/", "closeConnectionResponse"]] ],
      { :request_style =>  :document, :request_use =>  :literal,
        :response_style => :document, :response_use => :literal,
        :faults => {} }
    ]
  ]
end
end