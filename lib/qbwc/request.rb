class Qbwc::Request

  attr_reader   :request, :response_proc
  attr_accessor :response, :error

  def initialize(request, response_proc)
    @request = Qbwc.parser.hash_to_qbxml(request) 
    @response_proc = response_proc
  end

  def process_response
    @response_proc && @response && @response_proc.call(response) 
  end

  def to_qbxml
    Qbwc.parser.hash_to_qbxml(request)
  end

  def to_hash
    @request
  end

  class << self

    def from_array(requests, response_proc)
      Array(requests).map { |r| new(r, response_proc) } 
    end

  end

end
