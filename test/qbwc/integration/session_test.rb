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

    session = QBWC::Session.new(nil, COMPANY)

    assert_equal 2, QBWC.jobs.count
    assert_equal 2, QBWC.pending_jobs(COMPANY, session).count

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

  test "session ticket generated does not collide with others generated in the same second" do
    QBWC.add_job(:session_test_1, true, COMPANY, ConditionalTestWorker)

    Time.stub :now, Time.at(1466694710) do
      timothy_session  = QBWC::Session.new("timothy", COMPANY)
      margaret_session = QBWC::Session.new("margaret", COMPANY)

      assert timothy_session.ticket != margaret_session.ticket
    end
  end

  test "two sessions that advance to the next request_index should not clobber each other" do
    # In pseudocode, we are doing this:
    #   Advance Tim's request_index, mocking a delay between the SELECT and the UPDATE inside advance_next_request
    #   Advance Margaret's request index between Tim's SELECT and his UPDATE
    #   This would cause Margaret's update to effectively be rolled back because Tim ends up saving the wrong value for Margaret
    #
    # The solution is to perform the select and update inside of a transaction with locking,
    # ensuring that the record that is SELECTed doesn't change before it is UPDATEd.
    # This forces Margaret to wait until Tim has finished his operation before she can lock the row for her update.

    QBWC.add_job(:session_test_1, true, COMPANY, ConditionalTestWorker)

    timothy_session = QBWC::Session.new("timothy", COMPANY)
    margaret_session = QBWC::Session.new("margaret", COMPANY)

    job = QBWC.jobs.first

    delayed_save_for_tim = lambda do
      @@sleep_1_for_timothy_and_0_for_margaret ||= 1
      the_delay = @@sleep_1_for_timothy_and_0_for_margaret
      @@sleep_1_for_timothy_and_0_for_margaret = 0
      sleep(the_delay)

      self.send("__minitest_any_instance_stub__save")
    end

    QBWC::ActiveRecord::Job::QbwcJob.stub_any_instance(:save, delayed_save_for_tim) do
      threads = []
      threads << Thread.new {
        # This would not blow up in mysql (or any other real DBMS),
        # but since we're using sqlite3 to test, we look for an explosion
        error = assert_raises(ActiveRecord::StatementInvalid) do
          job.advance_next_request(timothy_session)
        end
        assert_match /SQLite3::BusyException/, error.message
      }

      threads << Thread.new {
        sleep(0.25)
        # This would not blow up in mysql (or any other real DBMS),
        # but since we're using sqlite3 to test, we look for an explosion
        error = assert_raises(ActiveRecord::StatementInvalid) do
          job.advance_next_request(margaret_session)
        end
        assert_match /SQLite3::BusyException/, error.message
      }

      threads.each { |thread| thread.join }
    end

    # Because both updates failed due to SQLite3's lack of graceful handling of locks, we expect that nothing changed.
    assert_equal 0, job.request_index(margaret_session)
    assert_equal 0, job.request_index(timothy_session)
    # In the "real" world, the DB would allow Margaret to wait for a lock, and then write.
    # We would be able to assert that both had advanced to 1.
  end

  test "two sessions that set requests should not clobber each other" do
    # same case as above, but with requests

    QBWC.add_job(:session_test_1, true, COMPANY, ConditionalTestWorker)

    timothy_session = QBWC::Session.new("timothy", COMPANY)
    margaret_session = QBWC::Session.new("margaret", COMPANY)
    timothy_requests = {:customer_query_rq => {:full_name => 'Timothy'}}
    margaret_requests = {:customer_query_rq => {:full_name => 'Margaret'}}

    job = QBWC.jobs.first

    delayed_save_for_tim = lambda do
      @@requests_sleep_1_for_timothy_and_0_for_margaret ||= 1
      the_delay = @@requests_sleep_1_for_timothy_and_0_for_margaret
      @@requests_sleep_1_for_timothy_and_0_for_margaret = 0
      sleep(the_delay)

      self.send("__minitest_any_instance_stub__save")
    end

    QBWC::ActiveRecord::Job::QbwcJob.stub_any_instance(:save, delayed_save_for_tim) do
      threads = []
      threads << Thread.new {
        # This would not blow up in mysql (or any other real DBMS),
        # but since we're using sqlite3 to test, we look for an explosion
        error = assert_raises(ActiveRecord::StatementInvalid) do
          job.set_requests(timothy_session, timothy_requests)
        end
        assert_match /SQLite3::BusyException/, error.message
      }

      threads << Thread.new {
        sleep(0.25)
        # This would not blow up in mysql (or any other real DBMS),
        # but since we're using sqlite3 to test, we look for an explosion
        error = assert_raises(ActiveRecord::StatementInvalid) do
          job.set_requests(margaret_session, margaret_requests)
        end
        assert_match /SQLite3::BusyException/, error.message
      }

      threads.each { |thread| thread.join }
    end

    # Because both updates failed due to SQLite3's lack of graceful handling of locks, we expect that nothing changed.
    assert_equal nil, job.requests(margaret_session)
    assert_equal nil, job.requests(timothy_session)
    # In the "real" world, the DB would allow Margaret to wait for a lock, and then write.
    # We could instead assert that both request hashes had persisted.
  end

  test "resetting a session doesn't reset other people's sessions" do
    QBWC.add_job(:session_test_1, true, COMPANY, ConditionalTestWorker)
    job = QBWC.jobs.first

    margaret_session = QBWC::Session.new("margaret", COMPANY)
    margaret_requests = [
      {:customer_query_rq => {:full_name => 'Margaret Customer 1'}},
      {:customer_query_rq => {:full_name => 'Margaret Customer 2'}}
    ]
    job.set_requests(margaret_session, margaret_requests)

    margaret_session.next_request

    timothy_session = QBWC::Session.new("timothy", COMPANY)
    timothy_requests = [
      {:customer_query_rq => {:full_name => 'Timothy Customer 1'}},
      {:customer_query_rq => {:full_name => 'Timothy Customer 2'}}
    ]
    job.set_requests(timothy_session, timothy_requests)

    assert_equal timothy_requests, job.requests(timothy_session)
    assert_equal margaret_requests, job.requests(margaret_session)
  end
end
