$:<< File.expand_path(File.dirname(__FILE__) + '/../..')
require 'test_helper.rb'

# http://pivotallabs.com/writing-rails-engine-rspec-controller-tests/
# http://jkamenik.github.io/blog/2014/02/07/controller-test-in-rails-engines/
# https://www.honeybadger.io/blog/2014/01/28/rails4-engine-controller-specs
class QBWCControllerTest < ActionController::TestCase

  def setup
    @routes = Rails.application.routes  # https://github.com/blowmage/minitest-rails/issues/133#issuecomment-36401436
    @controller = QbwcController.new    # http://stackoverflow.com/a/7743176
    @session = QBWC::Session.new('foo', '')

    @controller.prepend_view_path("#{Gem::Specification.find_by_name("wash_out").gem_dir}/app/views")
    #p @controller.view_paths

    QBWC.on_error = :stop
    QBWC::ActiveRecord::Session::QbwcSession.all.each {|qbs| qbs.destroy}
    QBWC.clear_jobs
    QBWC.set_session_initializer() {|session| }

    $HANDLE_RESPONSE_EXECUTED = false
  end

  def teardown
    QBWC.session_initializer = nil
    QBWC.session_complete_success = nil
  end

  test "qwc" do
    #_inspect_routes
    process(:qwc)

    assert_match(/QBWCXML/,                                                 @response.body)
    assert_match(Regexp.new("AppName.*QbwcTestApplication #{Rails.env}.*AppName"),       @response.body)
    assert_match(/AppURL.*http:\/\/test.host\/qbwc\/action.*AppURL/,        @response.body)
    assert_match(/AppDescription.*Quickbooks integration.*AppDescription/,  @response.body)
    assert_match(/AppSupport.*https:\/\/test.host\/.*AppSupport/,           @response.body)
    assert_match(/UserName.*#{QBWC_USERNAME}.*UserName/,                    @response.body)
    assert_match(/FileID.*{90A44FB5-33D9-4815-AC85-BC87A7E7D1EB}.*FileID/,  @response.body)
  end

  test "server_version" do
    _simulate_soap_request('server_version', SERVER_VERSION_SOAP_ACTION, SERVER_VERSION_PARAMS)
    assert_match(/tns:serverVersionResult/, @response.body)
  end

  test "authenticate with no jobs" do
    _authenticate
    assert_equal 0, QBWC.pending_jobs(COMPANY, @session).count
    assert @response.body.include?(QBWC::Controller::AUTHENTICATE_NO_WORK), @response.body
  end

  test "authenticate with jobs" do
    _authenticate_with_queued_job
    assert_equal 1, QBWC.pending_jobs(COMPANY, @session).count
    assert @response.body.include?(COMPANY), @response.body
  end

  test "authenticate fail" do
    _authenticate_wrong_password
    assert @response.body.include?(QBWC::Controller::AUTHENTICATE_NOT_VALID_USER), @response.body
  end

  test "authenticate with initialization block" do
     initializer_called = false
     QBWC.set_session_initializer() do |session|
        initializer_called = true
        assert_not_nil session
        assert_equal QBWC_USERNAME, session.user
        assert_equal 0, session.progress
        assert_nil session.error
        #assert_not_nil session.current_job
        #assert_not_nil session.pending_jobs
        #assert_equal 1, session.pending_jobs.count
     end

    _authenticate_with_queued_job
    assert initializer_called
  end

  test "most recent initialization block is executed" do
     initializer1_called = false
     initializer2_called = false

     QBWC.set_session_initializer() do |session|
        initializer1_called = true
     end

     QBWC.set_session_initializer() do |session|
        initializer2_called = true
     end

    _authenticate_with_queued_job
    assert ! initializer1_called
    assert   initializer2_called
  end

  test "send_request" do
    QBWC.add_job(:customer_add_rq_job, true, COMPANY, QBWC::Worker, QBWC_CUSTOMER_ADD_RQ)
    _authenticate
    _simulate_soap_request('send_request', SEND_REQUEST_SOAP_ACTION, SEND_REQUEST_PARAMS)
  end

  test "receive_response" do
    _authenticate_with_queued_job
    _simulate_soap_request('receive_response', RECEIVE_RESPONSE_SOAP_ACTION, RECEIVE_RESPONSE_PARAMS)

    assert_match(/tns:receiveResponseXMLResult.*100..tns:receiveResponseXMLResult/, @response.body)
  end

  class CheckErrorValuesWorker < QBWC::Worker
    def worker_assert_equal(expected_value, value, tag)
      raise "#{tag} is not correct" if expected_value != value && ! expected_value.blank?
    end

    def requests(job, session, data)
      {:customer_query_rq => {:full_name => 'Quincy Bob William Carlos'}}
    end

    def handle_response(response, session, job, request, expected)
      unless expected.blank?
        worker_assert_equal(expected[:session_error],           session.error,           "session.error")
        worker_assert_equal(expected[:session_status_code],     session.status_code,     "session.status_code")
        worker_assert_equal(expected[:session_status_severity], session.status_severity, "session.status_severity")
      end
      $HANDLE_RESPONSE_EXECUTED = true
    end
  end

  def _receive_response_error_helper(receive_response_xml_result, schedule_second_job)
    expected_values = {
      :session_error           => RECEIVE_RESPONSE_ERROR_PARAMS[:message],
      :session_status_code     => RECEIVE_RESPONSE_ERROR_PARAMS[:hresult],
      :session_status_severity => 'Error',
    }

    QBWC.add_job(:customer_add_rq_job1, true, COMPANY, CheckErrorValuesWorker, nil, expected_values)
    QBWC.add_job(:customer_add_rq_job2, true, COMPANY, CheckErrorValuesWorker) if schedule_second_job

    _authenticate
    _simulate_soap_request('receive_response', RECEIVE_RESPONSE_SOAP_ACTION, RECEIVE_RESPONSE_ERROR_PARAMS)

    assert $HANDLE_RESPONSE_EXECUTED  # https://github.com/skryl/qbwc/pull/50#discussion_r23764154
    assert_match(/tns:receiveResponseXMLResult.*#{receive_response_xml_result}..tns:receiveResponseXMLResult/, @response.body)
  end

  test "receive_response error stop" do
    QBWC.on_error = :stop
    _receive_response_error_helper(-1, false)
  end

  test "receive_response error continue" do
    QBWC.on_error = :continue
    _receive_response_error_helper(100, false)
  end

  test "receive_response error stop 2jobs" do
    QBWC.on_error = :stop
    _receive_response_error_helper(-1, true)
  end

  test "receive_response error continue 2jobs" do
    QBWC.on_error = :continue
    _receive_response_error_helper(50, true)
  end


  test "session_complete_success block called upon successful completion" do
    block_called = false
    QBWC.on_error = :stop
    QBWC.set_session_complete_success do |session|
      block_called = true
      assert_not_nil session
      assert_equal QBWC_USERNAME, session.user
      assert_equal 100, session.progress
      assert_not_nil session.began_at
    end

    _authenticate_with_queued_job
    _simulate_soap_request('receive_response', RECEIVE_RESPONSE_SOAP_ACTION, RECEIVE_RESPONSE_PARAMS)
    assert block_called
  end

  test "session_complete_success block not called upon failed completion" do
    block_called = false
    QBWC.on_error = :stop
    QBWC.session_complete_success = lambda do |session|
      block_called = true
    end

    _authenticate_with_queued_job
    _simulate_soap_request('receive_response', RECEIVE_RESPONSE_SOAP_ACTION, RECEIVE_RESPONSE_ERROR_PARAMS)
    assert !block_called
  end

end

