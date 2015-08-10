class QBWC::Job

  attr_reader :name, :company, :worker_class

  def initialize(name, enabled, company, worker_class, requests = [], data = nil)
    @name = name
    @enabled = enabled
    @company = company || QBWC.company_file_path
    @worker_class = worker_class
    @requests = requests
    @data = data
    @request_index = 0
  end

  def worker
    worker_class.constantize.new
  end

  def process_response(qbxml_response, response, session, advance)
    QBWC.logger.info "Processing response."
    completed_request = requests[request_index]
    advance_next_request if advance
    QBWC.logger.info "Job '#{name}' received response: '#{qbxml_response}'." if QBWC.log_requests_and_responses
    worker.handle_response(response, session, self, completed_request, data)
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

  def pending?(session)
    if !enabled?
      QBWC.logger.info "Job '#{name}' not enabled."
      return false
    end
    sr = worker.should_run?(self, session, @data)
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

  def next_request(session)
    # Generate and save the requests to run when starting the job.
    if (requests.nil? || requests.empty?) && ! self.requests_provided_when_job_added
      r = worker.requests(self, session, @data)
      r = [r] unless r.nil? || r.is_a?(Array)
      self.requests = r
    end

    QBWC.logger.info("Requests available are '#{requests}'.") if QBWC.log_requests_and_responses
    ri = request_index
    QBWC.logger.info("Request index is '#{ri}'.")
    return nil if ri.nil? || requests.nil? || ri >= requests.length
    nr = requests[ri]
    QBWC.logger.info("Next request is '#{nr}'.") if QBWC.log_requests_and_responses
    return QBWC::Request.new(nr)
  end
  alias :next :next_request  # Deprecated method name 'next'

  def reset
    self.request_index = 0
    self.requests = [] unless self.requests_provided_when_job_added
  end

end
