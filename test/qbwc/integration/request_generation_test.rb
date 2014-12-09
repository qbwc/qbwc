require 'test_helper.rb'

class RequestGenerationTest < ActionDispatch::IntegrationTest

  def setup
    RequestGenerationTest.app = Rails.application
    Rails.logger = Logger.new('/dev/null')  # or STDOUT
    QBWC.clear_jobs
  end

  def simulate_response(session)
    session.response = <<-EOF
    <?xml version="1.0"?><?qbxml version="7.0"?>
<QBXML>
  <QBXMLMsgsRs onError="stopOnError">
  </QBXMLMsgsRs>
</QBXML>
    EOF
  end

  test "worker with nothing" do
    QBWC.add_job(:integration_test, '', QBWC::Worker)
    session = QBWC::Session.new('foo', '')
    assert_nil session.next
  end

  class SingleRequestWorker < QBWC::Worker
    def requests
      {:foo => 'bar'}
    end
  end

  test "simple request worker" do
    QBWC.add_job(:integration_test, '', SingleRequestWorker)
    session = QBWC::Session.new('foo', '')
    assert_not_nil session.next
    simulate_response(session)
    assert_nil session.next
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
    QBWC.add_job(:integration_test, '', MultipleRequestWorker)
    session = QBWC::Session.new('foo', '')
    assert_not_nil session.next
    simulate_response(session)
    assert_not_nil session.next
    simulate_response(session)
    assert_nil session.next
  end

  test 'multiple jobs' do
    QBWC.add_job(:integration_test_1, '', SingleRequestWorker)
    QBWC.add_job(:integration_test_2, '', MultipleRequestWorker)
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
    QBWC.add_job(:integration_test, '', ShouldntRunWorker)
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
    QBWC.add_job(:integration_test, '', VariableRequestWorker)
    session = QBWC::Session.new('foo', '')
    assert_not_nil session.next
    simulate_response(session)
    # The number of requests should be fixed after the job starts.
    $VARIABLE_REQUEST_COUNT = 5
    assert_not_nil session.next
    simulate_response(session)
    assert_nil session.next
  end

end
