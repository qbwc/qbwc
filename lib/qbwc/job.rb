class QBWC::Job

  attr_accessor :data
  attr_reader :name, :company, :worker_class, :default_requests

  def initialize(name, enabled, company, worker_class, default_requests = [], data = nil)
    @name = name
    @enabled = enabled
    @company = company || QBWC.company_file_path
    @worker_class = worker_class
    @data = data
    @default_requests = [default_requests].flatten.compact
  end

  def worker
    @worker ||= worker_class.constantize.new
    @worker
  end

  def process_response(qbxml_response, response, session, advance)
    QBWC.logger.info "Processing response."
    QBWC.logger.info "Job '#{name}' received response: '#{qbxml_response}'." if QBWC.log_requests_and_responses

    completed_request = session.get_current_request(@default_requests)
    session.advance_next_request if advance

    worker.handle_response(response, session, self, completed_request, data)
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

    sr
  end

  def enabled?
    @enabled
  end

  def next_request(session = QBWC::Session.get)
    # Generate and save the requests to run when starting the job.
    if @default_requests.empty? && session.requests.nil?
      reqs = worker.requests(self, session, @data)
      reqs = [reqs].flatten.compact
      session.requests = reqs
    end

    next_request = session.get_current_request(@default_requests)
    QBWC.logger.info("Next request is '#{next_request}'.") if QBWC.log_requests_and_responses
    QBWC::Request.new(next_request) if next_request
  end
  alias :next :next_request  # Deprecated method name 'next'
end
