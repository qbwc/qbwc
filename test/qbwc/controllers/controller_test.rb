$:<< File.expand_path(File.dirname(__FILE__) + '/../..')  # (for wash_out_helper.rb)
require 'test_helper.rb'

# http://pivotallabs.com/writing-rails-engine-rspec-controller-tests/
# http://jkamenik.github.io/blog/2014/02/07/controller-test-in-rails-engines/
# https://www.honeybadger.io/blog/2014/01/28/rails4-engine-controller-specs
class QBWCControllerTest < ActionController::TestCase

  def setup
    @routes = Rails.application.routes  # https://github.com/blowmage/minitest-rails/issues/133#issuecomment-36401436
    @controller = QbwcController.new    # http://stackoverflow.com/a/7743176
    Rails.logger = Logger.new('/dev/null')  # or STDOUT

    @controller.prepend_view_path("#{Gem::Specification.find_by_name("wash_out").gem_dir}/app/views")
    #p @controller.view_paths

    QBWC.clear_jobs
    QBWC.set_session_initializer() {|session| }
  end

  test "qwc" do
    #_inspect_routes
    get 'qwc', use_route: :qbwc_qwc

    assert_match /QBWCXML/,                                                 @response.body
    assert_match /AppName.*QbwcTestApplication development.*AppName/,       @response.body
    assert_match /AppURL.*http:\/\/test.host\/qbwc\/action.*AppURL/,        @response.body
    assert_match /AppDescription.*Quickbooks integration.*AppDescription/,  @response.body
    assert_match /AppSupport.*https:\/\/test.host\/.*AppSupport/,           @response.body
    assert_match /UserName.*#{QBWC_USERNAME}.*UserName/,                    @response.body
  end

  test "authenticate with no jobs" do
    _authenticate
    assert_equal 0, QBWC.pending_jobs(COMPANY).count
    assert @response.body.include?(QBWC::Controller::AUTHENTICATE_NO_WORK), @response.body
  end

  test "authenticate with jobs" do
    _authenticate_with_queued_job
    assert_equal 1, QBWC.pending_jobs(COMPANY).count
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
    _authenticate_with_queued_job

    ticket = QBWC::ActiveRecord::Session::QbwcSession.first.ticket
    send_request_wash_out_soap_data = { :Envelope => { :Body => { SEND_REQUEST_SOAP_ACTION => SEND_REQUEST_PARAMS.update(:ticket => ticket) }}}

    # send_request
    @request.env["wash_out.soap_action"]  = SEND_REQUEST_SOAP_ACTION.to_s
    @request.env["wash_out.soap_data"]    = send_request_wash_out_soap_data
    @controller.env["wash_out.soap_data"] = @request.env["wash_out.soap_data"]

    post 'send_request', use_route: :qbwc_action
  end

end

