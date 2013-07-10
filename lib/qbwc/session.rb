class QBWC::Session

  attr_reader :user, :company, :ticket, :progress
  attr_accessor :error

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
    @iterator_id = nil

    @ticket = ticket || Digest::SHA1.hexdigest("#{Rails.application.config.secret_token}#{Time.now.to_i}")

    @@session = self
    reset(ticket.nil?)
  end

  def finished?
    self.progress == 100
  end

  def next
    until (request = current_job.next) do
      pending_jobs.shift
      reset(true) or break
    end
    self.progress = 100 if request.nil?
    request
  end

  def current_request
    request = self.next
    if request && self.iterator_id.present?
      request = request.to_hash
      request.delete('xml_attributes')
      request.values.first['xml_attributes'] = {'iterator' => 'Continue', 'iteratorID' => self.iterator_id}
      request = QBWC::Request.new(request)
    end 
    request
  end

  def response=(qbxml_response)
    begin
      response = QBWC.parser.from_qbxml(qbxml_response)["qbxml"]["qbxml_msgs_rs"].except("xml_attributes")
      response = response[response.keys.first]
      parse_response_header(response)
      self.current_job.process_response(response, self, iterator_id.blank?) unless self.error
      self.next unless self.error || self.iterator_id.present? # search next request
    rescue => e
      self.error = e.message
      Rails.logger.warn "An error occured in QBWC::Session: #{e.message}"
      Rails.logger.warn e.backtrace.join("\n")
    end
  end

  def save
  end

  def destroy
    self.freeze
    @@session = nil
  end

  protected

  attr_accessor :current_job, :iterator_id
  attr_writer :progress

  private

  def reset(reset_job = false)
    self.current_job = pending_jobs.first
    self.current_job.reset if reset_job && self.current_job
  end

  def pending_jobs
    @pending_jobs ||= QBWC.pending_jobs(@company)
  end

  def parse_response_header(response)
    self.iterator_id = nil
    response = response.first if response.is_a? Array
    return unless response.is_a?(Hash) && response['xml_attributes']

    @status_code, status_severity, status_message, iterator_remaining_count, iterator_id = \
      response['xml_attributes'].values_at('statusCode', 'statusSeverity', 'statusMessage', 
                                               'iteratorRemainingCount', 'iteratorID') 
    if status_severity == 'Error' || @status_code.to_i > 1
      self.error = "QBWC ERROR: #{@status_code} - #{status_message}"
    else
      self.iterator_id = iterator_id if iterator_remaining_count.to_i > 0
    end
  end
end
