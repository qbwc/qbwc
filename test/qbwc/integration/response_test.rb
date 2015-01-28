$:<< File.expand_path(File.dirname(__FILE__) + '/../..')
require 'test_helper.rb'

class ResponseTest < ActionDispatch::IntegrationTest

  def setup
    ResponseTest.app = Rails.application
    QBWC.on_error = :stop
    QBWC.clear_jobs

    $HANDLE_RESPONSE_DATA = nil
    $HANDLE_RESPONSE_IS_PASSED_DATA = false
  end

  class HandleResponseWithDataWorker < QBWC::Worker
    def requests(job)
      {:customer_query_rq => {:full_name => 'Quincy Bob William Carlos'}}
    end
    def handle_response(response, job, request, data)
      $HANDLE_RESPONSE_IS_PASSED_DATA = (data == $HANDLE_RESPONSE_DATA)
    end
  end

  test "handle_response is passed data" do
    $HANDLE_RESPONSE_DATA = {:first => {:second => 2, :third => '3'} }
    $HANDLE_RESPONSE_IS_PASSED_DATA = false
    QBWC.add_job(:integration_test, true, '', HandleResponseWithDataWorker, nil, $HANDLE_RESPONSE_DATA)
    session = QBWC::Session.new('foo', '')
    assert_not_nil session.next_request
    simulate_response(session)
    assert_nil session.next_request
    assert $HANDLE_RESPONSE_IS_PASSED_DATA
  end

  class HandleResponseOmitsJobWorker < QBWC::Worker
    def requests(job)
      {:customer_query_rq => {:full_name => 'Quincy Bob William Carlos'}}
    end
    def handle_response(*response)
      $HANDLE_RESPONSE_EXECUTED = true
    end
  end

  test "handle_response must use splat operator when omitting job argument" do
    $HANDLE_RESPONSE_EXECUTED = false
    QBWC.add_job(:integration_test, true, '', HandleResponseOmitsJobWorker)
    session = QBWC::Session.new('foo', '')
    assert_not_nil session.next_request
    simulate_response(session)
    assert_nil session.next_request
    assert $HANDLE_RESPONSE_EXECUTED
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
    QBWC.on_error = :stop

    # Add a job
    QBWC.add_job(:query_joe_customer, true, COMPANY, QueryAndDeleteWorker)

    # Simulate controller authenticate
    ticket_string = QBWC::ActiveRecord::Session.new(QBWC_USERNAME, COMPANY).ticket
    session = QBWC::Session.new(nil, COMPANY)

    # Simulate controller receive_response
    session.response = QBWC_CUSTOMER_QUERY_RESPONSE_WARN
    assert_equal 100, session.progress

    # Simulate controller send_request
    assert_nil session.next_request

    # Simulate arbitrary controller action
    session = QBWC::ActiveRecord::Session.get(ticket_string)  # simulated get_session
    session.save  # simulated save_session

  end

  test "processes error responses and deletes the job" do
    QBWC.on_error = :stop

    # Add a job
    QBWC.add_job(:query_joe_customer, true, COMPANY, QueryAndDeleteWorker)

    # Simulate controller authenticate
    ticket_string = QBWC::ActiveRecord::Session.new(QBWC_USERNAME, COMPANY).ticket
    session = QBWC::Session.new(nil, COMPANY)

    # Simulate controller receive_response
    session.response = QBWC_CUSTOMER_QUERY_RESPONSE_ERROR
    assert_equal 100, session.progress

    # Simulate controller send_request
    assert_nil session.next_request

    # Simulate controller get_last_error
    session = QBWC::ActiveRecord::Session.get(ticket_string)  # simulated get_session
    session.save  # simulated save_session

  end

  def _single_request_helper(response, expected_status_code, expected_status_severity, expected_session_error)
    error_string = "QBWC #{expected_status_severity.upcase}: #{expected_status_code} - #{expected_session_error}"

    # Simulate controller authenticate
    ticket_string = QBWC::ActiveRecord::Session.new(QBWC_USERNAME, COMPANY).ticket
    session = QBWC::Session.new(nil, COMPANY)

    # Simulate controller receive_response
    session.response = response
    assert_equal 100,                      session.progress
    assert_equal expected_status_code,     session.status_code
    assert_equal expected_status_severity, session.status_severity
    assert_equal error_string,             session.error

    # Simulate controller send_request
    assert_nil session.next_request
  end

  def _multi_request_helper(response1, expected_status_code1, expected_status_severity1, expected_session_error1, response2, expected_status_code2, expected_status_severity2, expected_session_error2, expected_progress1 = 50)

    error_string1 = "QBWC #{expected_status_severity1.upcase}: #{expected_status_code1} - #{expected_session_error1}"
    error_string2 = "QBWC #{expected_status_severity2.upcase}: #{expected_status_code2} - #{expected_session_error2}"

    # Simulate controller authenticate
    ticket_string = QBWC::ActiveRecord::Session.new(QBWC_USERNAME, COMPANY).ticket
    session = QBWC::Session.new(nil, COMPANY)

    # Simulate controller receive_response
    session.response = response1
    assert_equal expected_progress1,        session.progress
    assert_equal expected_status_code1,     session.status_code
    assert_equal expected_status_severity1, session.status_severity
    assert_equal error_string1,             session.error

    # Simulate controller send_request
    if session.progress == 100
      assert_nil(session.next_request)
      return
    else
      assert_not_nil(session.next_request)
    end

    # Simulate controller receive_response
    session.response = response2
    assert_equal 100,                       session.progress
    assert_equal expected_status_code2,     session.status_code
    assert_equal expected_status_severity2, session.status_severity
    assert_equal error_string2,             session.error

    assert_nil session.next_request
  end

  def _test_warning_then_error(expected_progress1 = 50)
    _multi_request_helper(
      QBWC_CUSTOMER_QUERY_RESPONSE_WARN,
      '500',
      'Warn',
      QBWC_CUSTOMER_QUERY_STATUS_MESSAGE_WARN,
      QBWC_CUSTOMER_QUERY_RESPONSE_ERROR,
      '3120',
      'Error',
      QBWC_CUSTOMER_QUERY_STATUS_MESSAGE_ERROR,
      expected_progress1)
  end

  def _test_error_then_warning(expected_progress1 = 50)
    _multi_request_helper(
      QBWC_CUSTOMER_QUERY_RESPONSE_ERROR,
      '3120',
      'Error',
      QBWC_CUSTOMER_QUERY_STATUS_MESSAGE_ERROR,
      QBWC_CUSTOMER_QUERY_RESPONSE_WARN,
      '500',
      'Warn',
      QBWC_CUSTOMER_QUERY_STATUS_MESSAGE_WARN,
      expected_progress1)
  end

  def _test_error_then_warning_that_stops
    _test_error_then_warning(100)
  end

  test "processes warning response stop" do
    QBWC.on_error = :stop
    QBWC.add_job(:query_joe_customer, true, COMPANY, HandleResponseWithDataWorker)
    _single_request_helper(QBWC_CUSTOMER_QUERY_RESPONSE_WARN, '500', 'Warn', QBWC_CUSTOMER_QUERY_STATUS_MESSAGE_WARN)
  end

  test "processes warning response continue" do
    QBWC.on_error = :continue
    QBWC.add_job(:query_joe_customer, true, COMPANY, HandleResponseWithDataWorker)
    _single_request_helper(QBWC_CUSTOMER_QUERY_RESPONSE_WARN, '500', 'Warn', QBWC_CUSTOMER_QUERY_STATUS_MESSAGE_WARN)
  end

  test "processes error response stop" do
    QBWC.on_error = :stop
    QBWC.add_job(:query_joe_customer, true, COMPANY, HandleResponseWithDataWorker)
    _single_request_helper(QBWC_CUSTOMER_QUERY_RESPONSE_ERROR, '3120', 'Error', QBWC_CUSTOMER_QUERY_STATUS_MESSAGE_ERROR)
  end

  test "processes error response continue" do
    QBWC.on_error = :continue
    QBWC.add_job(:query_joe_customer, true, COMPANY, HandleResponseWithDataWorker)
    _single_request_helper(QBWC_CUSTOMER_QUERY_RESPONSE_ERROR, '3120', 'Error', QBWC_CUSTOMER_QUERY_STATUS_MESSAGE_ERROR)
  end

  class MultiRequestWorker < QBWC::Worker
    def requests(job)
      [
        {:customer_query_rq => {:full_name => 'First Request'}},
        {:customer_query_rq => {:full_name => 'Second Request'}},
      ]
    end
    def handle_response(resp, job, request, data)
    end
  end

  test "processes warning then error stop 2jobs" do
    QBWC.on_error = :stop
    QBWC.add_job(:query_joe_customer,       true, COMPANY, HandleResponseWithDataWorker)
    QBWC.add_job(:query_joe_customer_again, true, COMPANY, HandleResponseWithDataWorker)

    _test_warning_then_error
  end

  test "processes warning then error continue 2jobs" do
    QBWC.on_error = :continue
    QBWC.add_job(:query_joe_customer,       true, COMPANY, HandleResponseWithDataWorker)
    QBWC.add_job(:query_joe_customer_again, true, COMPANY, HandleResponseWithDataWorker)

    _test_warning_then_error
  end

  test "processes warning then error stop 2requests byworker" do
    skip("Not correct yet")
    QBWC.on_error = :stop
    QBWC.add_job(:multiple_request_job, true, COMPANY, MultiRequestWorker)
    _test_warning_then_error
  end

  test "processes warning then error continue 2requests byworker" do
    skip("Not correct yet")
    QBWC.on_error = :continue
    QBWC.add_job(:multiple_request_job, true, COMPANY, MultiRequestWorker)
    _test_warning_then_error
  end

  test "processes warning then error stop 2requests byargument" do
    skip("Not correct yet")
    QBWC.on_error = :stop
    QBWC.add_job(:multiple_request_job, true, COMPANY, QBWC::Worker, [QBWC_CUSTOMER_QUERY_RQ, QBWC_CUSTOMER_QUERY_RQ])
    _test_warning_then_error
  end

  test "processes warning then error continue 2requests byargument" do
    skip("Not correct yet")
    QBWC.on_error = :continue
    QBWC.add_job(:multiple_request_job, true, COMPANY, QBWC::Worker, [QBWC_CUSTOMER_QUERY_RQ, QBWC_CUSTOMER_QUERY_RQ])
    _test_warning_then_error
  end

  test "processes error then warning stop 2jobs" do
    QBWC.on_error = :stop
    QBWC.add_job(:query_joe_customer,       true, COMPANY, HandleResponseWithDataWorker)
    QBWC.add_job(:query_joe_customer_again, true, COMPANY, HandleResponseWithDataWorker)
    _test_error_then_warning_that_stops
  end

  test "processes error then warning continue 2jobs" do
    QBWC.on_error = :continue
    QBWC.add_job(:query_joe_customer,       true, COMPANY, HandleResponseWithDataWorker)
    QBWC.add_job(:query_joe_customer_again, true, COMPANY, HandleResponseWithDataWorker)
    _test_error_then_warning
  end

  test "processes error then warning stop 2requests byworker" do
    skip("Not correct yet")
    QBWC.on_error = :stop
    QBWC.add_job(:multiple_request_job, true, COMPANY, MultiRequestWorker)
    _test_error_then_warning_that_stops
  end

  test "processes error then warning continue 2requests byworker" do
    skip("Not correct yet")
    QBWC.on_error = :continue
    QBWC.add_job(:multiple_request_job, true, COMPANY, MultiRequestWorker)
    _test_error_then_warning
  end

  test "processes error then warning stop 2requests byargument" do
    skip("Not correct yet")
    QBWC.on_error = :stop
    QBWC.add_job(:multiple_request_job, true, COMPANY, QBWC::Worker, [QBWC_CUSTOMER_QUERY_RQ, QBWC_CUSTOMER_QUERY_RQ])
    _test_error_then_warning_that_stops
  end

  test "processes error then warning continue 2requests byargument" do
    skip("Not correct yet")
    QBWC.on_error = :continue
    QBWC.add_job(:multiple_request_job, true, COMPANY, QBWC::Worker, [QBWC_CUSTOMER_QUERY_RQ, QBWC_CUSTOMER_QUERY_RQ])
    _test_error_then_warning
  end

end
