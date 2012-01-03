module QBWC
class Session
  include Enumerable

  attr_reader :index, :progress, :error
  @@sessions = {}

  # a request is a 2-tuple consisting of (xml_request, response_proc)
  #
  def initialize(name, parser = Quickbooks::API[QBWC.quickbooks_type], requests = [])
    @index = 0
    @progress = 0
    
    @parser = parser 
    @requests = requests
    @@sessions[name] = self
  end

  def request
    raise "out_of_bounds" if @progress == 100 || empty?
    @requests[@index].first
  end
  alias :current :request
  
  def requests
    @requests.map { |r| r.first }
  end

  def response_proc
    @requests[@index].last
  end

  def response_procs
    @requests.map { |r| r.last}
  end

  def process_response(response)
    response_proc.call(response) if response_proc
  end

# iteration
  
  def size
    @requests.size
  end
  alias :count :size

  def empty?
    size == 0
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

  def reset
    @index = 0
    @progress = 0
  end

  def finish!
    @index = size
    @progress = 100
  end

  def finished?
    @progress == 100
  end

# math

  def <<(session_item)
    size_old = @requests.size
    next_index = \
      if empty? 
        0
      elsif finished? 
        @index 
      else @index + 1
      end

    @requests.insert(next_index, session_item)
    @progress = @progress * size_old / (size_old + 1) 
  end

  def merge(session)
    cur_idx = @index
    @index = size - 1
    session.each do |r|
      self << r
    end
    session.finish!
    @index = cur_idx
  end

# processing

  def response=(response)
    begin
      resp_hash = @parser.qbxml_to_hash(response)

      if resp_hash['xml_attributes']
        status_code = resp_hash['xml_attributes']['statusCode']
        status_severity= resp_hash['xml_attributes']['statusSeverity']
        status_message = resp_hash['xml_attributes']['statusMessage']
        iterator_remaining = resp_hash['xml_attributes']['iteratorRemainingCount'].to_i
        iterator_id = resp_hash['xml_attributes']['iteratorID'] 
      end

      if status_severity == 'Error' || status_code.to_i > 0 || resp_hash.keys.size <= 1
        puts "QBWC ERROR: #{status_code} - #{status_message}"
      else
        process_response(resp_hash)
        if iterator_remaining > 0
          request_hash = @parser.qbxml_to_hash(request)
          nested_request = request_hash.detect { |k,v| k != 'xml_attributes' }.last
          nested_request['xml_attributes'] = {'iterator' => 'Continue', 'iteratorID' => iterator_id}
          
          if QBWC.quickbooks_type == :qbpos
            self << [@parser.hash_to_qbxml(:qbposxml_msgs_rq => request_hash), response_proc]
          else
            self << [@parser.hash_to_qbxml(:qbxml_msgs_rq => request_hash), response_proc]
          end
          
        end
      end
    rescue => e
      puts "An error occured in QBWC::Session: #{e}"
      puts e
      puts e.backtrace
    end
  end

  def each
    @requests.each do |r|
      yield r
    end
  end


class << self

  def [](session)
    @@sessions[session] || new_from_template(session)
  end

  def new_or_unfinished(session)
    self[session].finished? ? new_from_template(session) : self[session]
  end

  def new_from_template(template)
    parser, requests = QBWC::Templates[template]
    self.new(template, parser, requests)
  end

end

end
end