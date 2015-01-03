require 'spec_helper'

require 'active_support'
require 'active_record'
require 'action_controller'
require 'rails'

require 'qbwc'
require 'qbwc/session'
require 'qbwc/active_record'

# Stub Rails application
module SessionSpecApplication
  class Application < Rails::Application
  end
end

describe QBWC::Session do

  CUSTOMER_ADD_REQUEST = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\r
    <?qbxml version=\"7.0\"?>\r
    <QBXML>\r
      <QBXMLMsgsRq onError = \"stopOnError\">\r
        <CustomerAddRq>\r
          <CustomerAdd>\r
            <Name>mrjoecustomer</Name>\r
            <IsActive>1</IsActive>\r
            <CompanyName>Joes Garage</CompanyName>\r
            <Salutation>Mr</Salutation>\r
            <FirstName>Joe</FirstName>\r
            <LastName>Customer</LastName>\r
            <BillAddress>\r
              <Addr1>123 Main St.</Addr1>\r
              <City>Mountain View</City>\r
              <State>CA</State>\r
              <PostalCode>94566</PostalCode>\r
            </BillAddress>\r
            <Email>joecustomer@gmail.com</Email>\r
            <AccountNumber>89087</AccountNumber>\r
            <CreditLimit>2000.00</CreditLimit>\r
          </CustomerAdd>\r
        </CustomerAddRq>\r
      </QBXMLMsgsRq>\r
    </QBXML>\r"

  CUSTOMER_ADD_RESPONSE = "<?xml version=\"1.0\" ?><QBXML><QBXMLMsgsRs><CustomerAddRs statusCode=\"0\" statusSeverity=\"Info\" statusMessage=\"Status OK\"><CustomerRet><ListID>8000001B-1405768916</ListID><TimeCreated>2014-07-19T07:21:56-05:00</TimeCreated><TimeModified>2014-07-19T07:21:56-05:00</TimeModified><EditSequence>1405768916</EditSequence><Name>mrjoecustomer</Name><FullName>Joseph Customer</FullName><IsActive>true</IsActive><Sublevel>0</Sublevel><CompanyName>Joes Garage</CompanyName><Salutation>Mr</Salutation><FirstName>Joe</FirstName><LastName>Customer</LastName><BillAddress><Addr1>123 Main St.</Addr1><City>Mountain View</City><State>CA</State><PostalCode>94566</PostalCode></BillAddress><BillAddressBlock><Addr1>123 Main St.</Addr1><Addr2>Mountain View, CA 94566</Addr2></BillAddressBlock><Email>joecustomer@gmail.com</Email><Balance>0.00</Balance><TotalBalance>0.00</TotalBalance><AccountNumber>89087</AccountNumber><CreditLimit>2000.00</CreditLimit><JobStatus>None</JobStatus></CustomerRet></CustomerAddRs></QBXMLMsgsRs></QBXML>"

  CUSTOMER_QUERY_RESPONSE_WARN = "<?xml version=\"1.0\" ?><QBXML><QBXMLMsgsRs><CustomerQueryRs statusCode=\"500\" statusSeverity=\"Warn\" statusMessage=\"The query request has not been fully completed. There was a required element (&quot;bleech&quot;) that could not be found in QuickBooks.\" /></QBXMLMsgsRs></QBXML>"

  CUSTOMER_QUERY_RESPONSE_ERROR = "<?xml version=\"1.0\" ?><QBXML><QBXMLMsgsRs><CustomerQueryRs statusCode=\"3120\" statusSeverity=\"Error\" statusMessage=\"Object &quot;8000001B-1405768916&quot; specified in the request cannot be found.  QuickBooks error message: Invalid argument.  The specified record does not exist in the list.\" /></QBXMLMsgsRs></QBXML>"

  before do
    # http://stackoverflow.com/a/10605312
    ActiveRecord::Base.establish_connection(
      :adapter => 'sqlite3',
      :database => ':memory:'
    )

    require '../qbwc/lib/generators/qbwc/install/templates/db/migrate/create_qbwc_jobs'
    require '../qbwc/lib/generators/qbwc/install/templates/db/migrate/create_qbwc_sessions'
    ActiveRecord::Migration.run(CreateQbwcJobs)
    ActiveRecord::Migration.run(CreateQbwcSessions)

    # The gem uses Rails.logger
    Rails.logger = Logger.new('/dev/null')
    QBWC.logger = Rails.logger
  end

  class SessionSpecRequestWorker < QBWC::Worker
    def requests
      {:name => 'bleech'}
    end
  end

  it "sends request only once when providing a code block to add_job" do
    COMPANY = ''
    JOBNAME = 'add_joe_customer'

    QBWC.api = :qb

    # Add a job using only a code block
    QBWC.add_job(JOBNAME, true, COMPANY, SessionSpecRequestWorker) do
      CUSTOMER_ADD_REQUEST
    end

    expect(QBWC.jobs.count).to eq(1)
    expect(QBWC.pending_jobs(COMPANY).count).to eq(1)

    # Omit these controller calls that normally occur during a QuickBooks Web Connector session:
    # - server_version
    # - client_version
    # - authenticate
    # - send_request

    # Simulate controller receive_response
    session = QBWC::Session.new(nil, COMPANY)
    session.response = CUSTOMER_ADD_RESPONSE

    expect(session.progress).to eq(100)
  end

  class QueryAndDeleteWorker < QBWC::Worker
    def requests
      {:name => 'mrjoecustomer'}
    end

    def handle_response(resp, job, data)
       QBWC.delete_job(job.name)
    end
  end

  it "processes warning responses and deletes the job" do
    company = ''
    qbwc_username = 'myUserName'

    QBWC.api = :qb

    # Add a job
    QBWC.add_job(:query_joe_customer, true, company, QueryAndDeleteWorker)

    # Simulate controller receive_response
    ticket_string = QBWC::ActiveRecord::Session.new(qbwc_username, company).ticket
    session = QBWC::Session.new(nil, company)

    session.response = CUSTOMER_QUERY_RESPONSE_WARN
    expect(session.progress).to eq(100)

    # Simulate arbitrary controller action
    session = QBWC::ActiveRecord::Session.get(ticket_string)  # simulated get_session
    session.save  # simulated save_session

  end

  it "processes error responses and deletes the job" do
    company = ''
    qbwc_username = 'myUserName'

    QBWC.api = :qb

    # Add a job
    QBWC.add_job(:query_joe_customer, true, company, QueryAndDeleteWorker)

    # Simulate controller receive_response
    ticket_string = QBWC::ActiveRecord::Session.new(qbwc_username, company).ticket
    session = QBWC::Session.new(nil, company)

    session.response = CUSTOMER_QUERY_RESPONSE_ERROR
    expect(session.progress).to eq(0)

    # Simulate controller get_last_error
    session = QBWC::ActiveRecord::Session.get(ticket_string)  # simulated get_session
    session.save  # simulated save_session

  end

end
