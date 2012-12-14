class QBWC::Session

  attr_reader :progress

  @@session = nil

  def initialize
    @current_job = nil
    @current_request = nil

    @delayed_processing_queue = []
    @iterator_queue = []

    @iterating = false
    @@session = self

    reset!
  end

  def reset!
    @progress = QBWC.jobs.empty? ? 100 : 0
    @enabled_jobs = enabled_jobs.each { |j| j.reset }
    @request_gen = new_request_generator(@enabled_jobs)
  end

  def enabled_jobs
    QBWC.enabled_jobs.values
  end

  def enabled_jobs?
    !enabled_jobs.empty?
  end

  def request_queue
    enabled_jobs.map { j.requests }.flatten
  end

  def next
    @request_gen.alive? ? @request_gen.resume : nil
  end

  def finished?
    @progress == 100
  end

  def iterating?
    @iterating
  end

  # TODO: refactor
  #
  # def response=(qbxml_response)
  #   @current_request.response = QBWC.parser.from_qbxml(qbxml_response)
  #   parse_response_header(@current_request.response)

  #   if QBWC.delayed_processing
  #     @delayed_processing_queue << @current_request
  #   else
  #     @current_request.process_response
  #   end

  # rescue => e
  #   puts "An error occured in QBWC::Session: #{e}"
  #   puts e
  #   puts e.backtrace
  # end

  # def process_saved_responses
  #   @delayed_processing_queue.each { |r| r.process_response }
  # end

private

  def new_request_generator(jobs)
    Fiber.new do
      jobs.each do |j|
        @current_job = j
        while (r = next_request)
          @current_request = r
          Fiber.yield r
        end
      end

      @progress = 100
      nil
    end
  end

  def next_request
    (@iterating && @iterator_queue.shift) || @current_job.next
  end

  # TODO: refactor
  # def parse_response_header(response)
  #   return unless response['xml_attributes']

  #   status_code, status_severity, status_message, iterator_remaining_count, iterator_id = \
  #     response['xml_attributes'].values_at('statusCode', 'statusSeverity', 'statusMessage', 
  #                                          'iteratorRemainingCount', 'iteratorID') 
                                               
  #   if status_severity == 'Error' || status_code.to_i > 1 || response.keys.size <= 1
  #     @current_request.error = "QBWC ERROR: #{status_code} - #{status_message}"
  #   else
  #     if iterator_remaining_count.to_i > 0
  #       @iterating = true
  #       new_request = @current_request.to_hash
  #       new_request.delete('xml_attributes')
  #       new_request.values.first['xml_attributes'] = {'iterator' => 'Continue', 'iteratorID' => iterator_id}
  #       @iterator_queue << QBWC::Request.new(new_request, @current_request.response_proc)
  #     else
  #       @iterating = false
  #     end
  #   end
  # end

class << self

  def new_or_unfinished
    (!@@session || @@session.finished?) ? new : @@session
  end

end

	def self.session
		@@session
	end
end
