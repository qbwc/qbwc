class QBWC::Job

  attr_reader :name, :company, :response_proc, :next_request

  def initialize(name, company, *requests, &block)
    @name = name
    @enabled = true
    @company = company || QBWC.company_file_path
    @requests = requests
    @check_pending = proc { self.next }
    @next_request = 0

    if @requests.present?
      @request_gen = proc { @requests[next_request] }
      @request_gen_is_array = true
    else
      @request_gen = block
      @request_gen_is_array = false
    end
  end

  def set_checking_proc(&block) 
    @check_pending = block
    self
  end

  def set_response_proc(&block) 
    @response_proc = block
    self
  end

  def process_response(response, session, advance)
    advance_next_request if advance
    @response_proc.call(response, session) if @response_proc
  end

  def advance_next_request
    @request_gen_is_array ? @next_request += 1 : @request_gen = nil
  end

  def enable
    self.enabled = true
  end

  def disable
    self.enabled = false
  end

  def pending?
    enabled? && instance_eval(&@check_pending)
  end

  def self.enabled=(value)
    @enabled = value
  end

  def enabled?
    @enabled
  end

  def next
    request = instance_eval(&@request_gen) unless @request_gen.nil?
    QBWC::Request.new(request) if request
  end

  def reset
    @next_request = 0
  end

end
