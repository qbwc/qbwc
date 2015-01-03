class QBWC::ActiveRecord::Session < QBWC::Session
  class QbwcSession < ActiveRecord::Base
    attr_accessible :company, :ticket, :user unless Rails::VERSION::MAJOR >= 4
  end

	def self.get(ticket)
		session = QbwcSession.find_by_ticket(ticket)
    self.new(session) if session
	end

  def initialize(session_or_user = nil, company = nil, ticket = nil)
    if session_or_user.is_a? QbwcSession
      @session = session_or_user
      # Restore current job from saved one on QbwcSession
      @current_job = QBWC.get_job(@session.current_job) if @session.current_job
      # Restore pending jobs from saved list on QbwcSession
      @pending_jobs = @session.pending_jobs.split(',').map { |job_name| QBWC.get_job(job_name) }.select { |job| ! job.nil? }
      super(@session.user, @session.company, @session.ticket)
    else
      super
      @session = QbwcSession.new
      @session.user = self.user
      @session.company = self.company
      @session.ticket = self.ticket
      self.save
      @session
    end
  end

  def save
    @session.pending_jobs = pending_jobs.map(&:name).join(',')
    @session.current_job = current_job.try(:name)
    @session.save
    super
  end

  def destroy
    @session.destroy
    super
  end

  [:error, :progress, :iterator_id].each do |method|
    define_method method do
      @session.send(method)
    end
    define_method "#{method}=" do |value|
      @session.send("#{method}=", value)
    end
  end
  protected :progress=, :iterator_id=, :iterator_id

end
