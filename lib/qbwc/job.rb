class QBWC::Job
  include QBWC
  
  attr_reader :name, :request_proc, :response_proc
  private_class_method :new 

  def initialize(name, raw_requests = nil, request_proc = nil, response_proc = nil)
    @name = name
    @request_proc = request_proc
    @response_proc = response_proc
    @raw_requests = Array(raw_requests)
  end                       

  def raw_requests
    @raw_requests || (@request_proc && @request_proc.call)
  end

  def <<(raw_request)
    @raw_requests << raw_request
  end

class << self

  def new_static(name, requests, response_proc)
    new(name, requests, nil, response_proc)
  end

  def new_dynamic(name, request_generator, response_proc)
    new(name, nil, request_generator, response_proc)
  end

end

end
