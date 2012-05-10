class QBWC::Session
  include QBWC
  include Enumerable

  attr_reader :requests, :responses, :index, :progress, :error

  def initialize
    @index = 0
    @progress = 0
    
    @requests = build_request_queue(QBWC.enabled_jobs)
    @@session = self
  end

# request / response 

  def request
    raise "out_of_bounds" if @progress == 100 || empty?
    @requests[@index]
  end

  def qbxml_request
    QBWC.parser.hash_to_qbxml(request.raw_request)
  end

  def response=(qbxml_response)
    raw_response = QBWC.parser.qbxml_to_hash(qbxml_response)
    process_response_header(raw_response) if raw_response['xml_attributes']

    if QBWC.delayed_processing
      request.raw_response = raw_response
    else
      request.process_response(raw_response)
    end
  end

  def process_responses
    if QBWC.delayed_processing
      each { |r| r.process_response }
    end
  end

# iteration
  
  def reset
    @index = 0
    @progress = 0
  end

  def size
    @requests.size
  end

  def next
    val = request
    @index += 1

    if @requests[@index]
      @progress += 100/@requests.size
    else
      @progress = 100
    end

    val
  end

  def empty?
    size == 0
  end

  def finish!
    @index = size
    @progress = 100
  end

  def finished?
    @progress == 100
  end

  def each
    @requests.each do |r|
      yield r
    end
  end

  def <<(request)
    size_old = @requests.size
    next_index = \
      if empty? 
        0
      elsif finished? 
        @index 
      else @index + 1
      end

    @requests.insert(next_index, request)
    @progress = @progress * size_old / (size_old + 1) 
  end

private

  def process_response_header
    status_code, status_severity, status_message, iterator_remaining_count, iterator_id = \
      raw_response['xml_attributes'].values_at('statusCode', 'statusSeverity', 'statusMessage', 
                                               'iteratorRemainingCount', 'iteratorID') 

    if status_severity == 'Error' || status_code.to_i > 1 || resp_hash.keys.size <= 1
      puts "QBWC ERROR: #{status_code} - #{status_message}"
    else
      if iterator_remaining.to_i > 0
        request_with_attributes = raw_request.detect { |k,v| k != 'xml_attributes' }.last
        request_with_attributes['xml_attributes'] = {'iterator' => 'Continue', 'iteratorID' => iterator_id}
        self << Request.new(raw_request, response_proc)
      end
    end
  end

  def build_request_queue(jobs)
    jobs.map do |j| 
      j.requests.map { |r| Request.new(r, j.response_proc) }
    end.flatten 
  end

class << self

  def session
    @@session || self.new
  end

  def new_or_unfinished
    session.finished? ? self.new : session
  end

end

end
