class QBWC::Request

  attr_reader :raw_request, :response_proc
  attr_accessor :raw_response

  def initialize(raw_request, response_proc)
    @raw_request, @response_proc = raw_request, response_proc
  end

  def process_response(raw_response = @raw_response)
    @response_proc.call(raw_response) if @response_proc && raw_response
  end

end
