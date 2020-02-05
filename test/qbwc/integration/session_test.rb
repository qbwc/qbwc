$:<< File.expand_path(File.dirname(__FILE__) + '/../..')
require 'test_helper.rb'

class SessionTest < ActionDispatch::IntegrationTest

  def setup
    SessionTest.app = Rails.application
    QBWC.clear_jobs
  end

  class ProgressTestWorker < QBWC::Worker
    def requests(job, session, data)
      {:customer_query_rq => {:full_name => 'Quincy Bob William Carlos'}}
    end
  end

  test "progress increments when worker determines requests" do

    # Add two jobs
    QBWC.add_job(:session_test_1, true, COMPANY, ProgressTestWorker)
    QBWC.add_job(:session_test_2, true, COMPANY, ProgressTestWorker)

    session = QBWC::Session.new(nil, COMPANY)

    assert_equal 2, QBWC.jobs.count
    assert_equal 2, QBWC.pending_jobs(COMPANY, session).count

    # Simulate controller 1st send_request and receive_response
    session.response = QBWC_CUSTOMER_QUERY_RESPONSE_INFO
    assert_equal 50, session.progress

    # Simulate controller 2nd send_request and receive_response
    session.response = QBWC_CUSTOMER_QUERY_RESPONSE_INFO
    assert_equal 100, session.progress
  end

  test "progress increments when passing requests" do

    # Add two jobs
    QBWC.add_job(:session_test_1, true, COMPANY, QBWC::Worker, QBWC_CUSTOMER_ADD_RQ)
    QBWC.add_job(:session_test_2, true, COMPANY, QBWC::Worker, QBWC_CUSTOMER_QUERY_RQ)

    session = QBWC::Session.new(nil, COMPANY)

    assert_equal 2, QBWC.jobs.count
    assert_equal 2, QBWC.pending_jobs(COMPANY, session).count

    # Simulate controller 1st send_request and receive_response
    session.response = QBWC_CUSTOMER_ADD_RESPONSE_LONG
    assert_equal 50, session.progress

    # Simulate controller 2nd send_request and receive_response
    session.response = QBWC_CUSTOMER_QUERY_RESPONSE_INFO
    assert_equal 100, session.progress
  end

  test "sends request only once when passing requests to add_job" do

    # Add a job and pass a request
    QBWC.add_job(:add_joe_customer, true, COMPANY, QBWC::Worker, QBWC_CUSTOMER_ADD_RQ_LONG)

    # Simulate controller receive_response
    session = QBWC::Session.new(nil, COMPANY)
    session.response = QBWC_CUSTOMER_ADD_RESPONSE_LONG

    assert_equal 1, QBWC.jobs.count
    assert_equal 1, QBWC.pending_jobs(COMPANY, session).count

    # Omit these controller calls that normally occur during a QuickBooks Web Connector session:
    # - server_version
    # - client_version
    # - authenticate
    # - send_request

    assert_equal 100, session.progress
  end

  test "request_to_send when no requests" do

    QBWC.add_job(:add_joe_customer, true, COMPANY, QBWC::Worker, [])

    session = QBWC::Session.new(nil, COMPANY)

    assert_equal 1, QBWC.jobs.count
    assert_equal 1, QBWC.pending_jobs(COMPANY, session).count

    # Simulate controller send_request
    session.request_to_send
  end

  class ConditionalTestWorker < QBWC::Worker
    def should_run?(job, session, data)
      session.user != "margaret"
    end

    def requests(job, session, data)
      {:customer_query_rq => {:full_name => session.user}}
    end
  end

  test "worker can filter on user" do
    QBWC.add_job(:session_test_1, true, COMPANY, ConditionalTestWorker)

    timothy_session  = QBWC::Session.new("timothy", COMPANY)
    margaret_session = QBWC::Session.new("margaret", COMPANY)
    susan_session    = QBWC::Session.new("susan", COMPANY)

    # Should run for everyone except margaret
    assert_equal 1, QBWC.pending_jobs(COMPANY, timothy_session).count
    assert_equal 0, QBWC.pending_jobs(COMPANY, margaret_session).count
    assert_equal 1, QBWC.pending_jobs(COMPANY, susan_session).count

    # Simulate requests
    timothy_request = timothy_session.current_request
    assert timothy_request.request.include?("timothy")
    timothy_session.response = QBWC_CUSTOMER_QUERY_RESPONSE_INFO
    assert_equal 100, timothy_session.progress

    susan_request = susan_session.current_request
    assert susan_request.request.include?("susan")
    susan_session.response = QBWC_CUSTOMER_QUERY_RESPONSE_INFO
    assert_equal 100, susan_session.progress
  end


end
