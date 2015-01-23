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
    assert_equal 0, session.progress

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
    assert_equal 0, session.progress

    # Simulate controller 2nd send_request and receive_response
    request = session.current_request
    session.response = QBWC_CUSTOMER_QUERY_RESPONSE_INFO
    assert_equal 100, session.progress
  end

  class SessionSpecRequestWorker < QBWC::Worker
    def requests
      {:name => 'bleech'}
    end
  end

  test "sends request only once when providing a code block to add_job" do
    COMPANY = ''
    JOBNAME = 'add_joe_customer'

    QBWC.api = :qb

    # Add a job and pass a request
    QBWC.add_job(JOBNAME, true, COMPANY, SessionSpecRequestWorker, QBWC_CUSTOMER_ADD_RQ_LONG)

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

  class QueryAndDeleteWorker < QBWC::Worker
    def requests(job)
      {:name => 'mrjoecustomer'}
    end

    def handle_response(resp, job, request, data)
       QBWC.delete_job(job.name)
    end
  end

  test "processes warning responses and deletes the job" do
    company = ''
    qbwc_username = 'myUserName'

    QBWC.api = :qb

    # Add a job
    QBWC.add_job(:query_joe_customer, true, company, QueryAndDeleteWorker)

    # Simulate controller receive_response
    ticket_string = QBWC::ActiveRecord::Session.new(qbwc_username, company).ticket
    session = QBWC::Session.new(nil, company)

    session.response = QBWC_CUSTOMER_QUERY_RESPONSE_WARN
    assert_equal 100, session.progress

    # Simulate arbitrary controller action
    session = QBWC::ActiveRecord::Session.get(ticket_string)  # simulated get_session
    session.save  # simulated save_session

  end

  test "processes error responses and deletes the job" do
    company = ''
    qbwc_username = 'myUserName'

    QBWC.api = :qb

    # Add a job
    QBWC.add_job(:query_joe_customer, true, company, QueryAndDeleteWorker)

    # Simulate controller receive_response
    ticket_string = QBWC::ActiveRecord::Session.new(qbwc_username, company).ticket
    session = QBWC::Session.new(nil, company)

    session.response = QBWC_CUSTOMER_QUERY_RESPONSE_ERROR
    assert_equal 0, session.progress

    # Simulate controller get_last_error
    session = QBWC::ActiveRecord::Session.get(ticket_string)  # simulated get_session
    session.save  # simulated save_session

  end

end
