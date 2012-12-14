class QBWC::Job

  attr_reader :name, :requests, :response_proc

  def initialize(name, &block)
    @name = name
    @enabled = true
    @request_block = block

    reset!
  end

  def reset!
    @requests = collect_requests
    @request_gen = new_request_generator
  end

  def set_response_proc(&block) 
    @response_proc = block
  end

  def enable
    @enabled = true
  end

  def disable
    @enabled = false
  end

  def enabled?
    @enabled
  end

  def next
    @request_gen.alive? ? @request_gen.resume : nil
  end

private

  def new_request_generator
    Fiber.new { @requests.each { |r| Fiber.yield r }; nil }
  end

  def collect_requests
    QBWC::Request.from_array(@request_block.call, @response_proc )
  end

end
