class QBWC::Job

  attr_reader :name, :company, :worker_class

  def initialize(name, enabled, company, worker_class, requests = [], data = nil)
    @name = name
    @enabled = enabled
    @company = company || QBWC.company_file_path
    @worker_class = worker_class
    @worker_requests_called = get_persistent_value(:worker_requests_called)
    @requests = requests
    @data = data
    @request_index = 0
  end

  def worker
    worker_class.constantize.new
  end

  def process_response(response, session, advance)
    advance_next_request if advance
    QBWC.logger.info "Job '#{name}' received response: '#{response}'."
    worker.handle_response(response, self, data)
  end

  def advance_next_request
    new_index = request_index + 1
    QBWC.logger.info "Job '#{name}' advancing to request #'#{new_index}'."
    self.request_index = new_index
  end

  def enable
    self.enabled = true
  end

  def disable
    self.enabled = false
  end

  def pending?
    if !enabled?
      QBWC.logger.info "Job '#{name}' not enabled."
      return false
    end
    sr = worker.should_run?
    QBWC.logger.info "Job '#{name}' should_run?: #{sr}."
    return sr
  end

  def enabled?
    @enabled
  end

  def requests
    @requests
  end

  def requests=(r)
    @requests = r
  end

  def data
    @data
  end

  def data=(d)
    @data = d
  end

  def worker_requests_called
    @worker_requests_called
  end

  def worker_requests_called=(value)
    @worker_requests_called = value
  end

  def request_index
    @request_index
  end

  def request_index=(ri)
    @request_index = ri
  end

  def next_request
    # Generate and save the requests to run when starting the job.
    unless self.worker_requests_called
      r = worker.requests
      self.worker_requests_called = true
      unless r.nil?
        r = [r] if r.is_a?(Hash)
        self.requests = r
      end
    end

    QBWC.logger.info("Requests available are '#{requests}'.")
    ri = request_index
    QBWC.logger.info("Request index is '#{ri}'.")
    return nil if ri.nil? || requests.nil? || ri >= requests.length
    nr = requests[ri]
    QBWC.logger.info("Next request is '#{nr}'.")
    return QBWC::Request.new(nr)
  end
  alias :next :next_request  # Deprecated method name 'next'

  def reset
    self.request_index = 0
    #self.requests = []
  end

end
