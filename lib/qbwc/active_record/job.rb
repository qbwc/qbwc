class QBWC::ActiveRecord::Job < QBWC::Job
  class QbwcJob < ActiveRecord::Base
    validates :name, :uniqueness => { :case_sensitive => true }, :presence => true
    serialize :requests, Hash
    serialize :request_index, Hash
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
    ar_job.worker_class = worker_class
    ar_job.save!

    jb = self.new(name, enabled, company, worker_class, requests, data)
    unless requests.nil? || requests.empty?
      request_hash = { [nil, company] => [requests].flatten }

      jb.requests = request_hash
      ar_job.update_attribute :requests, request_hash
    end
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

  def requests(session = QBWC::Session.get)
    @requests = find_ar_job.pluck(:requests).first
    super
  end

  def set_requests(session, requests)
    super
    find_ar_job.update_all(:requests => @requests)
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

  def request_index(session)
    (find_ar_job.pluck(:request_index).first || {})[session.key] || 0
  end

  def set_request_index(session, index)
    find_ar_job.each do |jb|
      jb.request_index[session.key] = index
      jb.save
    end
  end

  def advance_next_request(session)
    nr = request_index(session)
    set_request_index session, nr + 1
  end

  def reset
    super
    job = find_ar_job
    job.update_all :request_index => {}
    job.update_all(:requests => {}) unless self.requests_provided_when_job_added
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
