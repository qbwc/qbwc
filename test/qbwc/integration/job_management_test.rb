$:<< File.expand_path(File.dirname(__FILE__) + '/../..')
require 'test_helper.rb'

class JobManagementTest < ActionDispatch::IntegrationTest

  REQUESTS_AS_HASH   = {:customer_query_rq => {:full_name => 'Quincy Bob William Carlos'}}
  REQUESTS_AS_STRING = QBWC_CUSTOMER_ADD_RQ

  def setup
    JobManagementTest.app = Rails.application
    Rails.logger = Logger.new('/dev/null')  # or STDOUT
    QBWC.clear_jobs
    @session = QBWC::Session.new('foo', '')
  end

  test "add_job" do
    QBWC.add_job(:integration_test, true, '', QBWC::Worker)
    assert_equal 1, QBWC.jobs.length

    # Overwrite existing job
    QBWC.add_job(:integration_test, true, 'my-company', QBWC::Worker)
    assert_equal 1, QBWC.jobs.length
  end

  test "add_job requests as hash" do
    QBWC.add_job(:integration_test, true, '', QBWC::Worker, REQUESTS_AS_HASH)
    assert_equal 1, QBWC.jobs.length
  end

  test "add_job requests as array of hashes" do
    QBWC.add_job(:integration_test, true, '', QBWC::Worker, [REQUESTS_AS_HASH])
    assert_equal 1, QBWC.jobs.length
  end

  test "add_job requests as string" do
    QBWC.add_job(:integration_test, true, '', QBWC::Worker, REQUESTS_AS_STRING)
    assert_equal 1, QBWC.jobs.length
  end

  test "add_job requests as array of strings" do
    QBWC.add_job(:integration_test, true, '', QBWC::Worker, [REQUESTS_AS_STRING])
    assert_equal 1, QBWC.jobs.length
  end

  test "requests" do
    job = QBWC.add_job(:integration_test, true, '', QBWC::Worker)
    session = QBWC::Session.new('foo', '')
    assert_nil job.requests(session)
  end

  test "requests with default session" do
    job = QBWC.add_job(:integration_test, true, '', QBWC::Worker)
    QBWC::Session.new('foo', '')
    assert_nil job.requests
  end

  test "next_request" do
    job = QBWC.add_job(:integration_test, true, '', QBWC::Worker)
    session = QBWC::Session.new('foo', '')
    assert_nil job.next_request(session)
  end

  test "next_request with default session" do
    job = QBWC.add_job(:integration_test, true, '', QBWC::Worker)
    QBWC::Session.new('foo', '')
    assert_nil job.next_request
  end

  test "pending_jobs" do
    QBWC.add_job(:integration_test, true, 'my-company', QBWC::Worker)
    assert_equal 1, QBWC.pending_jobs('my-company', @session).length
    assert_empty QBWC.pending_jobs('another-company', @session)
  end

  test "pending_jobs with default session" do
    QBWC.add_job(:integration_test, true, 'my-company', QBWC::Worker)
    assert_equal 1, QBWC.pending_jobs('my-company').length
    assert_empty QBWC.pending_jobs('another-company')
  end

  test "pending_jobs_disabled" do
    QBWC.add_job(:integration_test, false, 'my-company', QBWC::Worker)
    assert_empty QBWC.pending_jobs('my-company', @session)
  end

  test "get_job" do
    QBWC.add_job(:integration_test, true, 'my-company', QBWC::Worker)
    assert_not_nil QBWC.get_job(:integration_test)
    assert_nil QBWC.get_job(:doesnt_exist)
  end

  test "clear_jobs" do
    QBWC.add_job(:integration_test, true, 'my-company', QBWC::Worker)
    assert_equal 1, QBWC.jobs.length
    QBWC.clear_jobs
    assert_empty QBWC.jobs
  end

  test "delete_job by name" do
    jobname = :delete_job
    QBWC.add_job(jobname, true, 'my-company', QBWC::Worker)
    assert_not_nil QBWC.get_job(jobname)
    QBWC.delete_job(jobname)
    assert_nil QBWC.get_job(jobname)

    # Degenerate case does not crash
    QBWC.delete_job('')
  end

  test "delete_job by object" do
    jobname = :delete_job
    QBWC.add_job(jobname, true, 'my-company', QBWC::Worker)
    job = QBWC.get_job(jobname)
    QBWC.delete_job(job)
    assert_nil QBWC.get_job(jobname)

    # Degenerate case does not crash
    QBWC.delete_job(nil)
  end

  class DeleteJobWorker < QBWC::Worker
    def requests(job, session, data)
      REQUESTS_AS_HASH
    end

    def handle_response(resp, session, job, request, data)
      QBWC.delete_job(job.name)
    end
  end

  test "job deletes itself after running" do
    QBWC.add_job(:job_deletes_itself_after_running, true, COMPANY, DeleteJobWorker)
    session = QBWC::Session.new('foo', COMPANY)
    assert_equal 1, QBWC.pending_jobs(COMPANY, session).length
    assert_not_nil session.next_request
    simulate_response(session)
    assert_equal 0, QBWC.pending_jobs(COMPANY, session).length
  end

end
