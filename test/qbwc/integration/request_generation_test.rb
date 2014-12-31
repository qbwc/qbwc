$:<< File.expand_path(File.dirname(__FILE__) + '/../..')  # (for wash_out_helper.rb)
require 'test_helper.rb'

class RequestGenerationTest < ActionDispatch::IntegrationTest

  def setup
    RequestGenerationTest.app = Rails.application
    Rails.logger = Logger.new('/dev/null')  # or STDOUT
    QBWC.clear_jobs
  end

  test "worker with nothing" do
    QBWC.add_job(:integration_test, true, '', QBWC::Worker)
    session = QBWC::Session.new('foo', '')
    assert_nil session.next
  end

  class NilRequestWorker < QBWC::Worker
    def requests
      nil
    end
  end

  test "worker with nil" do
    QBWC.add_job(:integration_test, true, '', NilRequestWorker)
    session = QBWC::Session.new('foo', '')
    assert_nil session.next
    simulate_response(session)
    assert_nil session.next
  end

  class SingleRequestWorker < QBWC::Worker
    def requests
      {:foo => 'bar'}
    end
  end

  test "simple request worker" do
    QBWC.add_job(:integration_test, true, '', SingleRequestWorker)
    session = QBWC::Session.new('foo', '')
    assert_not_nil session.next
    simulate_response(session)
    assert_nil session.next
  end

  class HandleResponseOmitsJobWorker < QBWC::Worker
    def requests
      {:foo => 'bar'}
    end
    def handle_response(*response)
      $HANDLE_RESPONSE_EXECUTED = true
    end
  end

  test "handle_response must use splat operator when omitting job argument" do
    $HANDLE_RESPONSE_EXECUTED = false
    QBWC.add_job(:integration_test, true, '', HandleResponseOmitsJobWorker)
    session = QBWC::Session.new('foo', '')
    assert_not_nil session.next
    simulate_response(session)
    assert_nil session.next
    assert $HANDLE_RESPONSE_EXECUTED
  end

  class MultipleRequestWorker < QBWC::Worker
    def requests
      [
        {:foo => 'bar'},
        {:bar => 'foo'}
      ]
    end
  end

  test "multiple request worker" do
    QBWC.add_job(:integration_test, true, '', MultipleRequestWorker)
    session = QBWC::Session.new('foo', '')
    assert_not_nil session.next
    simulate_response(session)
    assert_not_nil session.next
    simulate_response(session)
    assert_nil session.next
  end

  test 'multiple jobs' do
    QBWC.add_job(:integration_test_1, true, '', SingleRequestWorker)
    QBWC.add_job(:integration_test_2, true, '', MultipleRequestWorker)
    assert_equal 2, QBWC.jobs.length
    session = QBWC::Session.new('foo', '')
    # one from SingleRequestWorker
    assert_not_nil session.next
    simulate_response(session)
    # two from MultipleRequestWorker
    assert_not_nil session.next
    simulate_response(session)
    assert_not_nil session.next
    simulate_response(session)
    assert_nil session.next
  end  

  class ShouldntRunWorker < QBWC::Worker
    def requests
      [
        {:foo => 'bar'},
        {:bar => 'foo'}
      ]
    end

    def should_run?
      false
    end
  end

  test "shouldnt run worker" do
    QBWC.add_job(:integration_test, true, '', ShouldntRunWorker)
    session = QBWC::Session.new('foo', '')
    assert_nil session.next
  end

  $VARIABLE_REQUEST_COUNT = 2
  class VariableRequestWorker < QBWC::Worker
    def requests
      r = []
      $VARIABLE_REQUEST_COUNT.times do
        r << {:foo => 'bar'}
      end
      return r
    end
  end

  test "variable request worker" do
    QBWC.add_job(:integration_test, true, '', VariableRequestWorker)
    session = QBWC::Session.new('foo', '')
    assert_not_nil session.next
    simulate_response(session)
    # The number of requests should be fixed after the job starts.
    $VARIABLE_REQUEST_COUNT = 5
    assert_not_nil session.next
    simulate_response(session)
    assert_nil session.next
  end

  class RequestsArgumentIgnoredByRequestWorker < QBWC::Worker
    def requests
      {:foo => 'bar'}
    end
  end

  test "requests argument ignored by request worker when requests is non-nil" do
    QBWC.add_job(:integration_test, true, '', RequestsArgumentIgnoredByRequestWorker, QBWC_CUSTOMER_ADD_RQ)
    session = QBWC::Session.new('foo', '')
    request = session.next
    assert_not_nil request
    assert_match /Foo.bar.\/Foo/, request.request
    simulate_response(session)
    assert_nil session.next

    assert_equal [{:foo => 'bar'}], QBWC::ActiveRecord::Job::QbwcJob.first[:requests]
  end

  class RequestsArgumentOverridesRequestWorker < QBWC::Worker
    def requests
      nil
    end
  end

  test "requests argument overrides request worker when requests is nil" do
    QBWC.add_job(:integration_test, true, '', RequestsArgumentOverridesRequestWorker, QBWC_CUSTOMER_ADD_RQ)
    session = QBWC::Session.new('foo', '')
    request = session.next
    assert_not_nil request
    assert_match /Name.#{QBWC_USERNAME}.\/Name/, request.request
    simulate_response(session)
    assert_nil session.next

    assert_equal [QBWC_CUSTOMER_ADD_RQ], QBWC::ActiveRecord::Job::QbwcJob.first[:requests]
  end

  class SimulatedUserModel
    attr_accessor :name
  end

  class RequestsArgumentEstablishesRequestEarlyWorker < QBWC::Worker
    def requests
      nil
    end
  end

  test "requests argument establishes request early" do
    usr = SimulatedUserModel.new
    usr.name = QBWC_USERNAME

    QBWC.add_job(:integration_test, true, '', RequestsArgumentEstablishesRequestEarlyWorker, {:name => usr.name})
    usr.name = 'bleech'

    session = QBWC::Session.new('foo', '')
    request = session.next
    assert_match /Name.#{QBWC_USERNAME}.\/Name/, request.request

    assert_equal [{:name => QBWC_USERNAME}], QBWC::ActiveRecord::Job::QbwcJob.first[:requests]
  end

  class RequestsArgumentReturnsMultipleRequestsWorker < QBWC::Worker
    def requests
      nil
    end
  end

  test "requests argument returns multiple requests" do
    usr1 = SimulatedUserModel.new
    usr1.name = QBWC_USERNAME

    usr2 = SimulatedUserModel.new
    usr2.name = 'usr2 name'

    multiple_requests = [
      {:name => usr1.name},
      {:name => usr2.name}
    ]
    QBWC.add_job(:integration_test, true, '', RequestsArgumentEstablishesRequestEarlyWorker, multiple_requests)
    usr1.name = 'bleech'
    usr2.name = 'bleech'

    session = QBWC::Session.new('foo', '')
    request1 = session.next
    assert_match /Name.#{QBWC_USERNAME}.\/Name/, request1.request
    simulate_response(session)

    request2 = session.next
    assert_match /Name.usr2 name.\/Name/, request2.request
    simulate_response(session)

    assert_nil session.next

    assert_equal [{:name => QBWC_USERNAME}, {:name => 'usr2 name'}], QBWC::ActiveRecord::Job::QbwcJob.first[:requests]
  end

end
