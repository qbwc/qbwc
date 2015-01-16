class QBWC::Job

  attr_reader :name, :company, :worker_class

  def initialize(name, enabled, company, worker_class, requests = [])
    @name = name
    @enabled = enabled
    @company = company || QBWC.company_file_path
    @worker_class = worker_class
    @requests = requests
    @request_index = 0
  end

  def worker
    worker_class.constantize.new
  end

  def process_response(response, session, advance)
    advance_next_request if advance
    QBWC.logger.info "Job '#{name}' received response: '#{response}'."
    worker.handle_response(response, self)
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

  def request_index
    @request_index
  end

  def request_index=(ri)
    @request_index = ri
  end

  def requests_provided_when_job_added
    @requests_provided_when_job_added
  end

  def requests_provided_when_job_added=(value)
    @requests_provided_when_job_added = value
  end

  def next
    # Generate and save the requests to run when starting the job.
    if (requests.nil? || requests.empty?) && ! self.requests_provided_when_job_added
      r = worker.requests
      r = [r] if r.is_a?(Hash)
      self.requests = r
    end

    QBWC.logger.info("Requests available are '#{requests}'.")
    ri = request_index
    QBWC.logger.info("Request index is '#{ri}'.")
    return nil if ri.nil? || requests.nil? || ri >= requests.length
    nr = requests[ri]
    QBWC.logger.info("Next request is '#{nr}'.")
    return QBWC::Request.new(nr)
  end

  def reset
    self.request_index = 0
    #self.requests = []
  end

end
