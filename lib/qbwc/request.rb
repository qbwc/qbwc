class QBWC::Request

  attr_reader   :request, :response_proc
  attr_accessor :response, :error

  def initialize(request, response_proc)
    @request = QBWC.parser.hash_to_qbxml(request) 
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

  def to_s
    @request
  end

  class << self

    def from_array(requests, response_proc)
      Array(requests).map { |r| new(r, response_proc) } 
    end

  end

end
