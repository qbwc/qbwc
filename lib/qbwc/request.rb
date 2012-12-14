class QBWC::Request

  attr_reader   :request, :response_proc
  attr_accessor :response, :error

  def initialize(request, response_proc)
    @request = \
      case request
      when Hash
        QBWC.parser.to_qbxml(request)
      else
        request.to_s
      end

    @response_proc = response_proc
  end

  def process_response
    @response_proc && 
    @response && 
    @response_proc.call(response) 
  end

  def to_hash
    QBWC.parser.from_qbxml @request
  end

  class << self

    def from_array(requests, response_proc)
      Array(requests).map { |r| new(r, response_proc) } 
    end

  end

end
