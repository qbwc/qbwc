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

  before do
    # http://stackoverflow.com/a/10605312
    ActiveRecord::Base.establish_connection(
      :adapter => 'sqlite3',
      :database => ':memory:'
    )

    ActiveRecord::Schema.define do
      self.verbose = false

      create_table "qbwc_jobs", force: true do |t|
        t.string   "name"
        t.string   "company",      limit: 1000
        t.boolean  "enabled",      		default: false, null: false
        t.integer  "next_request", 		default: 0,     null: false
        t.datetime "created_at"
        t.datetime "updated_at"
      end

      create_table "qbwc_sessions", force: true do |t|
        t.string   "ticket"
        t.string   "user"
        t.string   "company",      limit: 1000
        t.integer  "progress",                  default: 0,  null: false
        t.string   "current_job"
        t.string   "iterator_id"
        t.string   "error",        limit: 1000
        t.string   "pending_jobs", limit: 1000, default: "", null: false
        t.datetime "created_at"
        t.datetime "updated_at"
      end
    end

    # The gem uses Rails.logger
    Rails.logger = Logger.new(STDOUT)
  end

  it "sends request only once when providing a code block to add_job" do
    COMPANY = ''
    JOBNAME = 'add_joe_customer'

    QBWC.api = :qb

    # Add a job using only a code block
    QBWC::add_job(JOBNAME) do
      CUSTOMER_ADD_REQUEST
    end

    QBWC.jobs.count.should == 1
    QBWC.pending_jobs(COMPANY).count.should == 1

    # Omit these controller calls that normally occur during a QuickBooks Web Connector session:
    # - server_version
    # - client_version
    # - authenticate
    # - send_request

    # Simulate controller receive_response
    session = QBWC::Session.new(nil, COMPANY)
    session.response = CUSTOMER_ADD_RESPONSE

    session.progress.should == 100
  end

end
