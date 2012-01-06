class QBWC::Job
  
  attr_reader :name, :response_proc

  def initialize(name, requests, response_proc, opts = {})
    @name = name
    @requests = Array(requests)
    @response_proc = response_proc
  end

  def requests
    @requests.map { |r| Request.new(r, @response_proc) }
  end

  def <<(request)
    @requests << request.is_a?(Request) ? request.raw_request : request
  end

end
