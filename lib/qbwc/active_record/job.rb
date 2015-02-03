class QBWC::ActiveRecord::Job < QBWC::Job
  class QbwcJob < ActiveRecord::Base
    validates :name, :uniqueness => true, :presence => true
    serialize :requests, Array
    serialize :data

    def to_qbwc_job
      QBWC::ActiveRecord::Job.new(name, enabled, company, worker_class, requests, data)
    end

  end

  # Creates and persists a job.
  def self.add_job(name, enabled, company, worker_class, requests, data)

    worker_class = worker_class.to_s
    ar_job = find_ar_job_with_name(name).first_or_initialize
    ar_job.company = company
    ar_job.enabled = enabled
    ar_job.request_index = 0
    ar_job.worker_class = worker_class
    ar_job.save!

    jb = self.new(name, enabled, company, worker_class, requests, data)
    jb.requests = requests.is_a?(Array) ? requests : [requests] unless requests.nil?
    jb.requests_provided_when_job_added = (! requests.nil? && ! requests.empty?)
    jb.data = data

    jb
  end

  def self.find_job_with_name(name)
    j = find_ar_job_with_name(name).first
    j = j.to_qbwc_job unless j.nil?
    return j
  end

  def self.find_ar_job_with_name(name)
    QbwcJob.where(:name => name)
  end

  def find_ar_job
    self.class.find_ar_job_with_name(name)
  end

  def self.delete_job_with_name(name)
    j = find_ar_job_with_name(name).first
    j.destroy unless j.nil?
  end

  def enabled=(value)
    find_ar_job.update_all(:enabled => value)
  end

  def enabled?
    find_ar_job.where(:enabled => true).exists?
  end

  def requests
    find_ar_job.pluck(:requests).first
  end

  def requests=(r)
    find_ar_job.update_all(:requests => r)
    super
  end

  def requests_provided_when_job_added
    find_ar_job.pluck(:requests_provided_when_job_added).first
  end

  def requests_provided_when_job_added=(value)
    find_ar_job.update_all(:requests_provided_when_job_added => value)
    super
  end

  def data
    find_ar_job.pluck(:data).first
  end

  def data=(r)
    find_ar_job.update_all(:data => r)
    super
  end

  def request_index
    find_ar_job.pluck(:request_index).first
  end

  def request_index=(nr)
    find_ar_job.update_all(:request_index => nr)
  end

  def advance_next_request
    nr = request_index
    self.request_index = nr + 1
  end

  def self.list_jobs
    QbwcJob.all.map {|ar_job| ar_job.to_qbwc_job}
  end

  def self.clear_jobs
    QbwcJob.delete_all
  end

  def self.sort_in_time_order(ary)
    ary.sort {|a,b| a.find_ar_job.first.created_at <=> b.find_ar_job.first.created_at}
  end

end
