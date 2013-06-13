class QBWC::ActiveRecord::Job < QBWC::Job
  class QbwcJob < ActiveRecord::Base
    validates :name, :uniqueness => true, :presence => true
  end

  def initialize(name, company, &block)
    super
    find_job.first_or_create {|job| job.enabled = @enabled}
  end

  def find_job
    QbwcJob.where(:name => name)
  end

  def enabled=(value)
    find_job.update_all(:enabled => value)
  end

  def enabled?
    find_job.where(:enabled => true).exists?
  end
end
