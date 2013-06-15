class QBWC::ActiveRecord::Session < QBWC::Session
  class QbwcSession < ActiveRecord::Base
  end

	def self.get(ticket)
		session = QbwcSession.find_by_ticket(ticket)
    self.new(session) if session
	end

  def initialize(session_or_user = nil, company = nil, ticket = nil)
    if session_or_user.is_a? QbwcSession
      @session = session_or_user
      super(@session.user, @session.company, @session.ticket)
      # Restore current job from saved one on QbwcSession
      @current_job = QBWC.jobs[@session.current_job.to_sym] if @session.current_job
    else
      super
      @session = QbwcSession.new(:user => self.session_or_user, :company => self.company, :ticket => self.ticket)
    end
  end

  [:error, :progress, :qbwc_iterating].each do |method|
    define_method method do
      @session.send(method)
    end
    define_method "#{method}=" do |value|
      @session.send("#{method}=", value)
    end
  end
  private :error=, :progress=, :qbwc_iterating=, :qbwc_iterating

  def save
    @session.save
    super
  end

  def destroy
    @session.destroy
    super
  end

  private
  def self.current_job=(job)
    @session.current_job = job.try(:name)
    super
  end
end
