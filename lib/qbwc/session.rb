class QBWC::Session
  include Enumerable

  attr_reader :current_job, :current_request, :saved_requests, :progress
  attr_reader :qbwc_iterator_queue, :qbwc_iterating

  @@session = nil

  def initialize
    @current_job = nil
    @current_request = nil
    @saved_requests = []

    @qbwc_iterator_queue = []
    @qbwc_iterating = false

    @@session = self
    reset
  end

  def reset
    @progress = QBWC.jobs.blank? ? 100 : 0
    enabled_jobs.map { |j| j.reset } unless enabled_jobs.blank?
    @requests = build_request_generator(enabled_jobs)
  end

  def finished?
    @progress == 100
  end

  def next
    @requests.alive? ? @requests.resume : nil
  end

  def response=(qbxml_response)
    @current_request.response = \
      QBWC.parser.qbxml_to_hash(qbxml_response) 
    parse_response_header(@current_request.response)

    if QBWC.delayed_processing
      @saved_requests << @current_request
    else
      @current_request.process_response
    end
  end

  def process_saved_responses
    @saved_requests.each { |r| r.process_response }
  end

private

  def enabled_jobs
    QBWC.jobs.values.select { |j| j.enabled? } unless QBWC.jobs.empty?
  end

  def build_request_generator(jobs)
    Fiber.new do 
      unless jobs.blank?
        jobs.each do |j|
          @current_job = j
          while (r = next_request)
            @current_request = r
            Fiber.yield r
          end
        end
      end
      @progress = 100
      nil
    end
  end

  def next_request
    (@qbwc_iterating == true && @qbwc_iterator_queue.shift) || @current_job.next
  end

  def parse_response_header(response)
    return unless response['xml_attributes']

    status_code, status_severity, status_message, iterator_remaining_count, iterator_id = \
      response['xml_attributes'].values_at('statusCode', 'statusSeverity', 'statusMessage', 
                                               'iteratorRemainingCount', 'iteratorID') 
                                               
    if status_severity == 'Error' || status_code.to_i > 1 || response.keys.size <= 1
      @current_request.error = "QBWC ERROR: #{status_code} - #{status_message}"
    else
      if iterator_remaining_count.to_i > 0
        @qbwc_iterating = true
        new_request = @current_request.to_hash
        new_request.delete('xml_attributes')
        new_request.values.first['xml_attributes'] = {'iterator' => 'Continue', 'iteratorID' => iterator_id}
        @qbwc_iterator_queue << Request.new(new_request, @current_request.response_proc)
      else
        @qbwc_iterating = false
      end
    end
  end

class << self

  def new_or_unfinished
    (!@@session || @@session.finished?) ? new : @@session
  end

end

	def self.session
		@@session
	end
end
