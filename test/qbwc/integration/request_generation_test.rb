$:<< File.expand_path(File.dirname(__FILE__) + '/../..')
require 'test_helper.rb'

class RequestGenerationTest < ActionDispatch::IntegrationTest

  def setup
    RequestGenerationTest.app = Rails.application
    QBWC.clear_jobs
  end

  test "worker with nothing" do
    QBWC.add_job(:integration_test, true, '', QBWC::Worker)
    session = QBWC::Session.new('foo', '')
    assert_nil session.next_request
  end

  class NilRequestWorker < QBWC::Worker
    def requests(job, session, data)
      nil
    end
  end

  test "worker with nil" do
    QBWC.add_job(:integration_test, true, '', NilRequestWorker)
    session = QBWC::Session.new('foo', '')
    assert_nil session.next_request
    simulate_response(session)
    assert_nil session.next_request
  end

  class SingleRequestWorker < QBWC::Worker
    def requests(job, session, data)
      $SINGLE_REQUESTS_INVOKED_COUNT += 1 if defined?($SINGLE_REQUESTS_INVOKED_COUNT) && $SINGLE_REQUESTS_INVOKED_COUNT.is_a?(Integer)
      {:customer_query_rq => {:full_name => 'Quincy Bob William Carlos'}}
    end
  end

  test "simple request worker" do
    QBWC.add_job(:integration_test, true, '', SingleRequestWorker)
    QBWC.jobs.each {|job| assert job.requests_provided_when_job_added == false}
    session = QBWC::Session.new('foo', '')
    nr = session.next_request
    assert_not_nil nr
    assert_match(/FullName.*Quincy Bob William Carlos.*FullName/, nr.request)
    simulate_response(session)
    assert_nil session.next_request
  end

  class SingleStringRequestWorker < QBWC::Worker
    def requests(job, session, data)
      $SINGLE_REQUESTS_INVOKED_COUNT += 1 if defined?($SINGLE_REQUESTS_INVOKED_COUNT) && $SINGLE_REQUESTS_INVOKED_COUNT.is_a?(Integer)
      QBWC_CUSTOMER_QUERY_RQ
    end
  end

  test "simple string request worker" do
    QBWC.add_job(:integration_test, true, '', SingleStringRequestWorker)
    QBWC.jobs.each {|job| assert job.requests_provided_when_job_added == false}
    session = QBWC::Session.new('foo', '')
    nr = session.next_request
    assert_not_nil nr
    assert_match(/FullName.*#{QBWC_USERNAME}.*FullName/, nr.request)
    simulate_response(session)
    assert_nil session.next_request
  end

  class MultipleRequestWorker < QBWC::Worker
    def requests(job, session, data)
      $MULTIPLE_REQUESTS_INVOKED_COUNT += 1 if $MULTIPLE_REQUESTS_INVOKED_COUNT.is_a?(Integer)
      [
        {:customer_query_rq => {:full_name => 'Quincy Bob William Carlos'}},
        {:customer_query_rq => {:full_name => 'Quentin Billy Wyatt Charles'}}
      ]
    end
    def handle_response(response, session, job, request, data)
      $REQUESTS_FOUND_IN_RESPONSE = request
    end
  end

  test "multiple request worker" do
    $MULTIPLE_REQUESTS_INVOKED_COUNT = 0
    $REQUESTS_FOUND_IN_RESPONSE = []

    QBWC.add_job(:integration_test, true, '', MultipleRequestWorker)
    session = QBWC::Session.new('foo', '')
    assert_not_nil session.next_request
    simulate_response(session)
    assert_equal ({:customer_query_rq => {:full_name => 'Quincy Bob William Carlos'}}), $REQUESTS_FOUND_IN_RESPONSE

    assert_not_nil session.next_request
    simulate_response(session)
    assert_equal ({:customer_query_rq => {:full_name => 'Quentin Billy Wyatt Charles'}}), $REQUESTS_FOUND_IN_RESPONSE

    assert_nil session.next_request

    assert_equal 1, $MULTIPLE_REQUESTS_INVOKED_COUNT

    # requests should be generated once per session
    session2 = QBWC::Session.new('foo', '')
    assert_not_nil session2.next_request
    simulate_response(session2)
    assert_not_nil session2.next_request
    simulate_response(session2)
    assert_nil session2.next

    assert_equal 2, $MULTIPLE_REQUESTS_INVOKED_COUNT
  end

  class RequestsFromDbWorker < QBWC::Worker
    $REQUESTS_FROM_DB = [
        {:customer_query_rq => {:full_name => 'Quincy Bob William Carlos'}},
        {:customer_query_rq => {:full_name => 'Quentin Billy Wyatt Charles'}},
        {:customer_query_rq => {:full_name => 'Quigley Brian Wally Colin'}},
    ]

    def requests(job, session, data)
      $REQUESTS_FROM_DB
    end

    def handle_response(response, session, job, request, data)
      $REQUESTS_FROM_DB.shift  # Simulate marking first request as completed
      job.reset
    end
  end

  test 'multiple requests from db' do
    QBWC.add_job(:integration_test_multiple_requests_from_db, true, '', RequestsFromDbWorker)
    assert_equal 1, QBWC.jobs.length
    session = QBWC::Session.new('foo', '')

    req1 = session.next_request
    assert_not_nil req1
    assert_match(/xml.*FullName.*Quincy Bob William Carlos.*FullName/m, req1.request)
    simulate_response(session)

    req2 = session.next_request
    assert_not_nil req2
    assert_match(/xml.*FullName.*Quentin Billy Wyatt Charles.*FullName/m, req2.request)
    simulate_response(session)

    req3 = session.next_request
    assert_not_nil req3
    assert_match(/xml.*FullName.*Quigley Brian Wally Colin.*FullName/m, req3.request)
    simulate_response(session)

    assert_nil session.next_request
  end

  test 'multiple jobs' do
    $SINGLE_REQUESTS_INVOKED_COUNT   = 0
    $MULTIPLE_REQUESTS_INVOKED_COUNT = 0

    QBWC.add_job(:integration_test_1, true, '', SingleRequestWorker)
    QBWC.add_job(:integration_test_2, true, '', MultipleRequestWorker)
    assert_equal 2, QBWC.jobs.length
    session = QBWC::Session.new('foo', '')

    # one request from SingleRequestWorker
    assert_not_nil session.next_request
    simulate_response(session)

    # two requests from MultipleRequestWorker
    assert_not_nil session.next_request
    simulate_response(session)
    assert_not_nil session.next_request
    simulate_response(session)
    assert_nil session.next_request

    assert_equal 1, $SINGLE_REQUESTS_INVOKED_COUNT
    assert_equal 1, $MULTIPLE_REQUESTS_INVOKED_COUNT
  end  

  test 'multiple jobs using different request techniques' do
    $MULTIPLE_REQUESTS_INVOKED_COUNT = 0

    QBWC.add_job(:integration_test_1, true, '', SingleRequestWorker)
    QBWC.add_job(:integration_test_2, true, '', MultipleRequestWorker, QBWC_CUSTOMER_ADD_RQ)
    QBWC.jobs.each {|job| assert job.requests_provided_when_job_added == (job.name == 'integration_test_2')}
    session = QBWC::Session.new('foo', '')

    assert_equal 2, QBWC.pending_jobs('', session).count

    # one request from SingleRequestWorker
    assert_not_nil session.next_request
    simulate_response(session)

    # Requests from MultipleRequestWorker are suppressed; instead use one request passed when job added
    assert_not_nil session.next_request
    simulate_response(session)
    assert_nil session.next

    assert_equal 0, $MULTIPLE_REQUESTS_INVOKED_COUNT
    QBWC.jobs.each {|job| assert job.requests_provided_when_job_added == (job.name == 'integration_test_2')}
  end

  # https://github.com/skryl/qbwc/issues/58
  test 'multiple jobs when first job has no requests' do
    QBWC.add_job(:test_empty,  true, '', QBWC::Worker, [])
    QBWC.add_job(:test_income, true, '', QBWC::Worker, [{:account_query_rq => {:active_status => 'All', :account_type => 'Income'}}])
    session = QBWC::Session.new('foo', '')

    # No requests from :test_empty

    # One request from :test_income
    assert_not_nil session.next_request
    simulate_response(session)
    assert_nil session.next_request
  end

  class ShouldntRunWorker < QBWC::Worker
    def requests(job, session, data)
      [
        {:customer_query_rq => {:full_name => 'Quincy Bob William Carlos'}},
        {:customer_query_rq => {:full_name => 'Quentin Billy Wyatt Charles'}}
      ]
    end

    def should_run?(job, session, data)
      false
    end
  end

  test "shouldnt run worker" do
    QBWC.add_job(:integration_test, true, '', ShouldntRunWorker)
    session = QBWC::Session.new('foo', '')
    assert_nil session.next_request
  end

  $VARIABLE_REQUEST_COUNT = 2
  class VariableRequestWorker < QBWC::Worker
    def requests(job, session, data)
      r = []
      $VARIABLE_REQUEST_COUNT.times do
        r << {:customer_query_rq => {:full_name => 'Quincy Bob William Carlos'}}
      end
      return r
    end
  end

  test "variable request worker" do
    QBWC.add_job(:integration_test, true, '', VariableRequestWorker)
    session = QBWC::Session.new('foo', '')
    assert_not_nil session.next_request
    simulate_response(session)
    # The number of requests should be fixed after the job starts.
    $VARIABLE_REQUEST_COUNT = 5
    assert_not_nil session.next_request
    simulate_response(session)
    assert_nil session.next_request
  end

  class RequestsArgumentSuppressesRequestWorker < QBWC::Worker
    def requests(job)
      {:foo => 'bar'}
    end
  end

  test "requests argument suppresses request worker" do
    QBWC.add_job(:integration_test, true, '', RequestsArgumentSuppressesRequestWorker, QBWC_CUSTOMER_ADD_RQ)
    QBWC.jobs.each {|job| assert job.requests_provided_when_job_added == true}
    session = QBWC::Session.new('foo', '')
    request = session.next_request
    assert_not_nil request
    assert_match(/CustomerAddRq.*\/CustomerAddRq/m, request.request)
    simulate_response(session)
    assert_nil session.next_request

    assert_match(/CustomerAddRq.*\/CustomerAddRq/m, extract_request(QBWC::ActiveRecord::Job::QbwcJob.first, session)[0])
    QBWC.jobs.each {|job| assert job.requests_provided_when_job_added == true}
  end

  class RequestsArgumentOverridesRequestWorker < QBWC::Worker
    def requests(job)
      nil
    end
  end

  class SimulatedUserModel
    attr_accessor :name
  end

  class RequestsArgumentEstablishesRequestEarlyWorker < QBWC::Worker
    def requests(job)
      nil
    end
  end

  test "requests argument establishes request early" do
    usr = SimulatedUserModel.new
    usr.name = QBWC_USERNAME

    QBWC.add_job(:integration_test, true, '', RequestsArgumentEstablishesRequestEarlyWorker, {:customer_query_rq => {:full_name => QBWC_USERNAME}})
    QBWC.jobs.each {|job| assert job.requests_provided_when_job_added == true}
    usr.name = 'bleech'

    session = QBWC::Session.new('foo', '')
    request = session.next_request
    assert_not_nil request
    assert_match(/FullName.#{QBWC_USERNAME}.\/FullName/, request.request)

    expected = {[nil, ""] => [{:customer_query_rq => {:full_name => QBWC_USERNAME}}]}
    assert_equal expected, QBWC::ActiveRecord::Job::QbwcJob.first[:requests]
    QBWC.jobs.each {|job| assert job.requests_provided_when_job_added == true}
  end

  class RequestsArgumentReturnsMultipleRequestsWorker < QBWC::Worker
    def requests(job)
      nil
    end
  end

  test "requests argument returns multiple requests" do
    usr1 = SimulatedUserModel.new
    usr1.name = QBWC_USERNAME

    usr2 = SimulatedUserModel.new
    usr2.name = 'usr2 name'

    multiple_requests = [
      {:customer_query_rq => {:full_name => usr1.name}},
      {:customer_query_rq => {:full_name => usr2.name}}
    ]
    QBWC.add_job(:integration_test, true, '', RequestsArgumentEstablishesRequestEarlyWorker, multiple_requests)
    QBWC.jobs.each {|job| assert job.requests_provided_when_job_added == true}
    usr1.name = 'bleech'
    usr2.name = 'bleech'

    session = QBWC::Session.new('foo', '')
    request1 = session.next_request
    assert_match(/FullName.#{QBWC_USERNAME}.\/FullName/, request1.request)
    simulate_response(session)

    request2 = session.next_request
    assert_match(/FullName.usr2 name.\/FullName/, request2.request)
    simulate_response(session)

    assert_nil session.next_request

    assert_equal multiple_requests[0], extract_request(QBWC::ActiveRecord::Job::QbwcJob.first, session)[0]
    assert_equal multiple_requests[1], extract_request(QBWC::ActiveRecord::Job::QbwcJob.first, session)[1]
    QBWC.jobs.each {|job| assert job.requests_provided_when_job_added == true}
  end


  def extract_request(ar_job, session)
    requests = ar_job[:requests]
    secondary_key = session.key.dup
    secondary_key[0] = nil # username = nil
    result = nil
    [session.key, secondary_key].each do |k|
      result ||= (requests || {})[k]
    end
    result
  end

end
