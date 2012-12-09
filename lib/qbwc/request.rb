class QBWC::Request

  attr_reader   :request, :response_proc
  attr_accessor :response, :error

  def initialize(request, response_proc)
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

      @request = QBWC.parser.hash_to_qbxml(request)
    when request.is_a?(String)
      @request = request
    end
    @response_proc = response_proc
  end

  def process_response
    @response_proc && @response && @response_proc.call(response) 
  end

  def to_qbxml
    QBWC.parser.hash_to_qbxml(request)
  end

  def to_hash
    QBWC.parser.qbxml_to_hash @request.to_s
  end

  class << self

    def from_array(requests, response_proc)
      Array(requests).map { |r| new(r, response_proc) } 
    end

  end

end
