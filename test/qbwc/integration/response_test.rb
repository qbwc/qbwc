$:<< File.expand_path(File.dirname(__FILE__) + '/../..')
require 'test_helper.rb'

class ResponseTest < ActionDispatch::IntegrationTest

  WARN_RESPONSE = {
    :response => QBWC_CUSTOMER_QUERY_RESPONSE_WARN,
    :code     => '500',
    :severity => 'Warn',
    :message  => QBWC_CUSTOMER_QUERY_STATUS_MESSAGE_WARN,
  }
  ERROR_RESPONSE = {
    :response => QBWC_CUSTOMER_QUERY_RESPONSE_ERROR,
    :code     => '3120',
    :severity => 'Error',
    :message  => QBWC_CUSTOMER_QUERY_STATUS_MESSAGE_ERROR,
  }

  def setup
    ResponseTest.app = Rails.application
    QBWC.on_error = :stop
    QBWC.clear_jobs

    $HANDLE_RESPONSE_EXECUTED = false
    $HANDLE_RESPONSE_DATA = nil
    $HANDLE_RESPONSE_IS_PASSED_DATA = false
  end

  def _receive_responses(*responses)

    # Simulate controller authenticate
    ticket_string = QBWC::ActiveRecord::Session.new(QBWC_USERNAME, COMPANY).ticket
    assert_not_nil(ticket_string)

    session = QBWC::Session.new(nil, COMPANY)

    responses.each do |resp|
      expect_error = "QBWC #{resp[:severity].upcase}: #{resp[:code]} - #{resp[:message]}"

      # Simulate controller receive_response
      $HANDLE_RESPONSE_EXECUTED = false
      session.response = resp[:response]
      assert_equal resp[:progress], session.progress unless resp[:progress].nil?
      assert_equal resp[:code],     session.status_code
      assert_equal resp[:severity], session.status_severity
      assert_equal expect_error,    session.error
      assert $HANDLE_RESPONSE_EXECUTED

      # Simulate controller send_request
      if session.progress == 100
        assert_nil(session.next_request)
        return
      end

      assert_not_nil(session.next_request)
    end

  end

  def _test_warning_then_error(expected_progress1 = 50)
    warn  = WARN_RESPONSE.merge(:progress => expected_progress1)
    error = ERROR_RESPONSE.merge(:progress => 100)

    _receive_responses(warn, error)
  end

  def _test_error_then_warning(expected_progress1 = 50)
    error = ERROR_RESPONSE.merge(:progress => expected_progress1)
    warn  = WARN_RESPONSE.merge(:progress => 100)

    _receive_responses(error, warn)
  end

  def _test_error_then_warning_that_stops
    _test_error_then_warning(100)
  end

  class HandleResponseWithDataWorker < QBWC::Worker
    def requests(job, session, data)
      {:customer_query_rq => {:full_name => 'Quincy Bob William Carlos'}}
    end
    def handle_response(response, session, job, request, data)
      $HANDLE_RESPONSE_EXECUTED = true
      $HANDLE_RESPONSE_IS_PASSED_DATA = (data == $HANDLE_RESPONSE_DATA)
    end
  end

  test "handle_response is passed data" do
    $HANDLE_RESPONSE_DATA = {:first => {:second => 2, :third => '3'} }
    $HANDLE_RESPONSE_IS_PASSED_DATA = false
    QBWC.add_job(:integration_test, true, '', HandleResponseWithDataWorker, nil, $HANDLE_RESPONSE_DATA)
    session = QBWC::Session.new('foo', '')
    assert_not_nil session.next_request
    simulate_response(session, QBWC_CUSTOMER_ADD_RESPONSE_LONG)
    assert_nil session.next_request
    assert $HANDLE_RESPONSE_IS_PASSED_DATA
  end

  class HandleResponseRaisesExceptionWorker < QBWC::Worker
    def requests(job, session, data)
      {:customer_query_rq => {:full_name => 'Quincy Bob William Carlos'}}
    end
    def handle_response(response, session, job, request, data)
      raise "Exception in handle_response"
    end
  end

  test "handle_response raises exception" do
    QBWC.add_job(:integration_test, true, '', HandleResponseRaisesExceptionWorker)
    session = QBWC::Session.new('foo', '')
    assert_not_nil session.next_request
    simulate_response(session)
    assert_nil session.next_request
    assert_equal "Exception in handle_response", session.error
  end

  class HandleResponseOmitsJobWorker < QBWC::Worker
    def requests(job, session, data)
      {:customer_query_rq => {:full_name => 'Quincy Bob William Carlos'}}
    end
    def handle_response(*response)
      $HANDLE_RESPONSE_EXECUTED = true
    end
  end

  test "handle_response must use splat operator when omitting remaining arguments" do
    QBWC.add_job(:integration_test, true, '', HandleResponseOmitsJobWorker)
    session = QBWC::Session.new('foo', '')
    assert_not_nil session.next_request
    simulate_response(session)
    assert_nil session.next_request
    assert $HANDLE_RESPONSE_EXECUTED
  end

  class QueryAndDeleteWorker < QBWC::Worker
    def requests(job, session, data)
      {:name => 'mrjoecustomer'}
    end

    def handle_response(resp, session, job, request, data)
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

  test "processes warning response stop" do
    QBWC.on_error = :stop
    QBWC.add_job(:query_joe_customer, true, COMPANY, HandleResponseWithDataWorker)
    _receive_responses(WARN_RESPONSE.merge(:progress => 100))
  end

  test "processes warning response continue" do
    QBWC.on_error = :continue
    QBWC.add_job(:query_joe_customer, true, COMPANY, HandleResponseWithDataWorker)
    _receive_responses(WARN_RESPONSE.merge(:progress => 100))
  end

  test "processes error response stop" do
    QBWC.on_error = :stop
    QBWC.add_job(:query_joe_customer, true, COMPANY, HandleResponseWithDataWorker)
    _receive_responses(ERROR_RESPONSE.merge(:progress => 100))
  end

  test "processes error response continue" do
    QBWC.on_error = :continue
    QBWC.add_job(:query_joe_customer, true, COMPANY, HandleResponseWithDataWorker)
    _receive_responses(ERROR_RESPONSE.merge(:progress => 100))
  end

  class MultiRequestWorker < QBWC::Worker
    def requests(job, session, data)
      [
        {:customer_query_rq => {:full_name => 'First Request'}},
        {:customer_query_rq => {:full_name => 'Second Request'}},
      ]
    end
    def handle_response(resp, session, job, request, data)
      $HANDLE_RESPONSE_EXECUTED = true
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
    QBWC.on_error = :stop
    QBWC.add_job(:multiple_request_job, true, COMPANY, MultiRequestWorker)
    _test_warning_then_error(0)
  end

  test "processes warning then error continue 2requests byworker" do
    QBWC.on_error = :continue
    QBWC.add_job(:multiple_request_job, true, COMPANY, MultiRequestWorker)
    _test_warning_then_error(0)
  end

  test "processes warning then error stop 2requests byargument" do
    QBWC.on_error = :stop
    QBWC.add_job(:multiple_request_job, true, COMPANY, HandleResponseWithDataWorker, [QBWC_CUSTOMER_QUERY_RQ, QBWC_CUSTOMER_QUERY_RQ])
    _test_warning_then_error(0)
  end

  test "processes warning then error continue 2requests byargument" do
    QBWC.on_error = :continue
    QBWC.add_job(:multiple_request_job, true, COMPANY, HandleResponseWithDataWorker, [QBWC_CUSTOMER_QUERY_RQ, QBWC_CUSTOMER_QUERY_RQ])
    _test_warning_then_error(0)
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
    QBWC.on_error = :stop
    QBWC.add_job(:multiple_request_job, true, COMPANY, MultiRequestWorker)
    _test_error_then_warning_that_stops
  end

  test "processes error then warning continue 2requests byworker" do
    QBWC.on_error = :continue
    QBWC.add_job(:multiple_request_job, true, COMPANY, MultiRequestWorker)
    _test_error_then_warning(0)
  end

  test "processes error then warning stop 2requests byargument" do
    QBWC.on_error = :stop
    QBWC.add_job(:multiple_request_job, true, COMPANY, HandleResponseWithDataWorker, [QBWC_CUSTOMER_QUERY_RQ, QBWC_CUSTOMER_QUERY_RQ])
    _test_error_then_warning_that_stops
  end

  test "processes error then warning continue 2requests byargument" do
    QBWC.on_error = :continue
    QBWC.add_job(:multiple_request_job, true, COMPANY, HandleResponseWithDataWorker, [QBWC_CUSTOMER_QUERY_RQ, QBWC_CUSTOMER_QUERY_RQ])
    _test_error_then_warning(0)
  end

end
