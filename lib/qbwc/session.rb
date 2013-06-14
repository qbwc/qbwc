class QBWC::Session

  attr_reader :user, :company, :current_job
  attr_accessor :progress, :error, :qbwc_iterating

  @@session = nil

	def self.get(ticket)
		@@session
	end

  def initialize(user = nil, company = nil)
    @user = user
    @company = company
    @current_job = nil
    @error = nil
    @progress = 0
    @qbwc_iterating = false

    @ticket = Digest::SHA1.hexdigest "#{Rails.application.config.secret_token}#{Time.now.to_i}"

    @@session = self
    self.reset
  end

  def reset
    self.current_job = pending_jobs.first
    self.current_job.reset if self.current_job
  end

  def finished?
    @progress == 100
  end

  def next
    until (request = current_job.next) do
      pending_jobs.unshift
      self.reset or break
    end
    self.progress = 100 if request.nil?
  end

  def current_request
    request = self.next
    request = QBWC.storage_module::Request.new(request) if request
    if request && @qbwc_iterating
      request = request.to_hash
      request.delete('xml_attributes')
      request.values.first['xml_attributes'] = {'iterator' => 'Continue', 'iteratorID' => iterator_id}
      request = QBWC.storage_module::Request.new(request)
    end 
    request
  end

  def response=(qbxml_response)
    begin
      response = QBWC.parser.from_qbxml(qbxml_response)
      parse_response_header(response)
      self.current_job.process_response(response, !@qbwc_iterating)
      self.next unless @qbwc_iterating # search next request
    rescue => e
      self.error = e.message
      puts "An error occured in QBWC::Session: #{e}"
      puts e
      puts e.backtrace
    end
  end

  def destroy
    self.freeze
    @@session = nil
  end

  protected
  def self.current_job=(job)
    @current_job = j
  end

  private

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
      self.qbwc_iterating = if iterator_remaining_count.to_i > 0
    end
  end
end
