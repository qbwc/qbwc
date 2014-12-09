class QBWC::Request

  attr_reader   :request, :response_proc

  def initialize(request)
    #Handle Cases for a request passed in as a Hash or String
    #If it's a hash verify that it is properly wrapped with qbxml_msg_rq and xml_attributes for on_error events
    #Allow strings of QBXML to be passed in directly. 
    case
    when request.is_a?(Hash)

      unless request.keys.include?(:qbxml_msgs_rq)
        wrapped_request = { :qbxml_msgs_rq => {:xml_attributes => {"onError"=> QBWC::on_error } } } 
        wrapped_request[:qbxml_msgs_rq] = wrapped_request[:qbxml_msgs_rq].merge(request)
        request = wrapped_request
      end

      @request = "<?xml version=\"1.0\"?>#{QBWC.parser.to_qbxml(request)}"
    when request.is_a?(String)
      @request = request
    else
      raise "Request '#{request}' must be a Hash or a String."
    end
  end

  def to_qbxml
    QBWC.parser.to_qbxml(request)
  end

  def to_hash
    hash = QBWC.parser.from_qbxml(@request.to_s)["qbxml"]["qbxml_msgs_rq"]
    hash.except('xml_attributes')
  end

end
