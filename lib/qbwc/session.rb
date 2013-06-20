class QBWC::Session

  attr_reader :user, :company, :ticket, :progress, :error

  @@session = nil

	def self.get(ticket)
		@@session
	end

  def initialize(user = nil, company = nil, ticket = nil)
    @user = user
    @company = company
    @current_job = nil
    @error = nil
    @progress = 0
    @qbwc_iterating = false

    @ticket = ticket || Digest::SHA1.hexdigest("#{Rails.application.config.secret_token}#{Time.now.to_i}")

    @@session = self
    reset(ticket.nil?)
  end

  def finished?
    self.progress == 100
  end

  def next
    until (request = current_job.next) do
      pending_jobs.unshift
      reset(true) or break
    end
    self.progress = 100 if request.nil?
    request
  end

  def current_request
    request = self.next
    request = Request.new(request) if request
    if request && self.qbwc_iterating
      request = request.to_hash
      request.delete('xml_attributes')
      request.values.first['xml_attributes'] = {'iterator' => 'Continue', 'iteratorID' => iterator_id}
      request = Request.new(request)
    end 
    request
  end

  def response=(qbxml_response)
    begin
      response = QBWC.parser.from_qbxml(qbxml_response)
      parse_response_header(response)
      self.current_job.process_response(response, !qbwc_iterating) unless self.error
      self.next unless self.error || self.qbwc_iterating # search next request
    rescue => e
      self.error = e.message
      puts "An error occured in QBWC::Session: #{e}"
      puts e
      puts e.backtrace
    end
  end

  def save
  end

  def destroy
    self.freeze
    @@session = nil
  end

  protected

  attr_accessor :qbwc_iterating, :current_job
  attr_writer :progress, :error

  private

  def reset(reset_job = false)
    self.current_job = pending_jobs.first
    self.current_job.reset if reset_job && self.current_job
  end

  def pending_jobs
    @pending_jobs ||= QBWC.pending_jobs(@company)
  end

  def parse_response_header(response)
    return unless response['xml_attributes']

    status_code, status_severity, status_message, iterator_remaining_count, iterator_id = \
      response['xml_attributes'].values_at('statusCode', 'statusSeverity', 'statusMessage', 
                                               'iteratorRemainingCount', 'iteratorID') 
                                               
    if status_severity == 'Error' || status_code.to_i > 1 || response.keys.size <= 1
      self.error = "QBWC ERROR: #{status_code} - #{status_message}"
    else
      self.qbwc_iterating = iterator_remaining_count.to_i > 0
    end
  end
end
