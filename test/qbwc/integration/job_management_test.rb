require 'test_helper.rb'

class JobManagementTest < ActionDispatch::IntegrationTest

  def setup
    JobManagementTest.app = Rails.application
    Rails.logger = Logger.new('/dev/null')  # or STDOUT
    QBWC.clear_jobs
  end

  test "add_job" do
    QBWC.add_job(:integration_test, true, '', QBWC::Worker)
    assert_equal 1, QBWC.jobs.length

    # Overwrite existing job
    QBWC.add_job(:integration_test, true, 'my-company', QBWC::Worker)
    assert_equal 1, QBWC.jobs.length
  end

  test "pending_jobs" do
    QBWC.add_job(:integration_test, true, 'my-company', QBWC::Worker)
    assert_equal 1, QBWC.pending_jobs('my-company').length
    assert_empty QBWC.pending_jobs('another-company')
  end

  test "pending_jobs_disabled" do
    QBWC.add_job(:integration_test, false, 'my-company', QBWC::Worker)
    assert_empty QBWC.pending_jobs('my-company')
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

end
