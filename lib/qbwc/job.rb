class Qbwc::Job

  attr_reader :name, :response_proc, :requests

  def initialize(name, &block)
    @name = name
    @enabled = true
    @requests = block

    reset
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

  def reset
    @request_gen = new_request_generator
  end

private

  def new_request_generator
    Fiber.new { request_queue.each { |r| Fiber.yield r }; nil }
  end

  def request_queue
    Qbwc::Request.from_array(@requests.call, @response_proc )
  end

end
