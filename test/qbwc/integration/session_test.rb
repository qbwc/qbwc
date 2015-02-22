$:<< File.expand_path(File.dirname(__FILE__) + '/../..')
require 'test_helper.rb'

class SessionTest < ActionDispatch::IntegrationTest

  def setup
    SessionTest.app = Rails.application
    QBWC.clear_jobs
  end

  class ProgressTestWorker < QBWC::Worker
    def requests(job)
      {:customer_query_rq => {:full_name => 'Quincy Bob William Carlos'}}
    end
  end

  test "progress increments when worker determines requests" do

    # Add two jobs
    QBWC.add_job(:session_test_1, true, COMPANY, ProgressTestWorker)
    QBWC.add_job(:session_test_2, true, COMPANY, ProgressTestWorker)

    assert_equal 2, QBWC.jobs.count
    assert_equal 2, QBWC.pending_jobs(COMPANY).count

    session = QBWC::Session.new(nil, COMPANY)

    # Simulate controller 1st send_request and receive_response
    request = session.current_request
    session.response = QBWC_CUSTOMER_QUERY_RESPONSE_INFO
    assert_equal 50, session.progress

    # Simulate controller 2nd send_request and receive_response
    request = session.current_request
    session.response = QBWC_CUSTOMER_QUERY_RESPONSE_INFO
    assert_equal 100, session.progress
  end

  test "progress increments when passing requests" do

    # Add two jobs
    QBWC.add_job(:session_test_1, true, COMPANY, QBWC::Worker, QBWC_CUSTOMER_ADD_RQ)
    QBWC.add_job(:session_test_2, true, COMPANY, QBWC::Worker, QBWC_CUSTOMER_QUERY_RQ)

    assert_equal 2, QBWC.jobs.count
    assert_equal 2, QBWC.pending_jobs(COMPANY).count

    session = QBWC::Session.new(nil, COMPANY)

    # Simulate controller 1st send_request and receive_response
    request = session.current_request
    session.response = QBWC_CUSTOMER_ADD_RESPONSE_LONG
    assert_equal 50, session.progress

    # Simulate controller 2nd send_request and receive_response
    request = session.current_request
    session.response = QBWC_CUSTOMER_QUERY_RESPONSE_INFO
    assert_equal 100, session.progress
  end

  test "sends request only once when passing requests to add_job" do

    # Add a job and pass a request
    QBWC.add_job(:add_joe_customer, true, COMPANY, QBWC::Worker, QBWC_CUSTOMER_ADD_RQ_LONG)

    assert_equal 1, QBWC.jobs.count
    assert_equal 1, QBWC.pending_jobs(COMPANY).count

    # Omit these controller calls that normally occur during a QuickBooks Web Connector session:
    # - server_version
    # - client_version
    # - authenticate
    # - send_request

    # Simulate controller receive_response
    session = QBWC::Session.new(nil, COMPANY)
    session.response = QBWC_CUSTOMER_ADD_RESPONSE_LONG

    assert_equal 100, session.progress
  end

  test "request_to_send when no requests" do

    QBWC.add_job(:add_joe_customer, true, COMPANY, QBWC::Worker, [])

    assert_equal 1, QBWC.jobs.count
    assert_equal 1, QBWC.pending_jobs(COMPANY).count

    # Simulate controller send_request
    session = QBWC::Session.new(nil, COMPANY)
    request = session.request_to_send
  end

end
