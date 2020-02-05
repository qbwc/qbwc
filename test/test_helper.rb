# http://stackoverflow.com/a/4402193
require 'bundler/setup'
Bundler.setup

require 'minitest/autorun'
require 'byebug'

require 'active_support'
require 'active_record'
require 'action_controller'
require 'rails'

# Determine location of local wash_out gem
# https://github.com/rubygems/rubygems/blob/master/lib/rubygems/commands/which_command.rb
require 'rubygems/commands/which_command'
which_command = Gem::Commands::WhichCommand.new
paths = which_command.find_paths('wash_out', $LOAD_PATH)
wash_out_lib = File.dirname(paths[0])  # Alternate technique: File.dirname(`gem which wash_out`)

# Add wash_out to autoload_paths so that WashOutHelper can be included directly
# http://api.rubyonrails.org/classes/AbstractController/Helpers/ClassMethods.html#method-i-helper
# http://guides.rubyonrails.org/autoloading_and_reloading_constants.html#require-dependency
# http://guides.rubyonrails.org/autoloading_and_reloading_constants.html#autoload-paths
ActiveSupport::Dependencies.autoload_paths << "#{wash_out_lib}/../app/helpers"

$:<< File.expand_path(File.dirname(__FILE__) + '/../lib')
require 'qbwc'
require 'qbwc/controller'
require 'qbwc/active_record'

COMPANY = 'c:\\QuickBooks\MyFile.QBW'
QBWC_USERNAME = 'myUserName'
QBWC_PASSWORD = 'myPassword'
QBWC.api = :qb

ActiveSupport::TestCase.test_order = :random if defined? ActiveSupport::TestCase.test_order=()

#-------------------------------------------
# http://coryforsyth.com/2013/06/02/programmatically-list-routespaths-from-inside-your-rails-app/
def _inspect_routes
  puts "\nRoutes:"
  Rails.application.routes.routes.each do |route|
    puts "  Name #{route.name}: \t #{route.verb.source.gsub(/[$^]/, '')} #{route.path.spec.to_s}"
  end
  puts "\n"
end

#-------------------------------------------
# Stub Rails application
module QbwcTestApplication
  class Application < Rails::Application
    Rails.application.configure do
      config.secret_key_base = "stub"
      config.eager_load = false
      if config.respond_to?(:hosts)
        config.hosts << 'www.example.com'
        config.hosts << ''
      end
    end
    ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
    require '../qbwc/lib/generators/qbwc/install/templates/db/migrate/create_qbwc_jobs'
    require '../qbwc/lib/generators/qbwc/install/templates/db/migrate/index_qbwc_jobs'
    require '../qbwc/lib/generators/qbwc/install/templates/db/migrate/change_request_index'
    require '../qbwc/lib/generators/qbwc/install/templates/db/migrate/create_qbwc_sessions'
    ActiveRecord::Migration.run(CreateQbwcJobs)
    ActiveRecord::Migration.run(IndexQbwcJobs)
    ActiveRecord::Migration.run(ChangeRequestIndex)
    ActiveRecord::Migration.run(CreateQbwcSessions)
    QBWC.configure do |c|
      c.username = QBWC_USERNAME
      c.password = QBWC_PASSWORD
      c.company_file_path = COMPANY
      c.session_initializer = Proc.new{|session| $CONFIG_SESSION_INITIALIZER_PROC_EXECUTED = true }
    end

    # Logger
    Rails.logger = Logger.new('/dev/null')  # or STDOUT
    QBWC.logger = Rails.logger
  end

end

def _assign_routes

  # Manually stub these generated routes:
  #          GET        /qbwc/action(.:format)  qbwc#_generate_wsdl
  # qbwc_qwc GET        /qbwc/qwc(.:format)     qbwc#qwc
  get 'qbwc/action' => 'qbwc#_generate_wsdl'
  get 'qbwc/qwc'    => 'qbwc#qwc',            :as => :qbwc_qwc

  # Add these routes:
  # qbwc_wsdl   GET        /qbwc/wsdl              qbwc#_generate_wsdl
  # qbwc_action GET|POST   /qbwc/action            #<WashOut::Router:0x00000005cf46d0 @controller_name="QbwcController">
  wash_out :qbwc

  # Route needed for test_qwc 
  get 'qbwc/action' => 'qbwc#action'

  get 'qbwc/authenticate' => 'qbwc#authenticate'

  # Stub a root route
  root :to => "qbwc#qwc"
end

QbwcTestApplication::Application.routes.draw do
  _assign_routes
end

class QbwcController < ActionController::Base
  protect_from_forgery with: :exception  # Must precede QWBC::Controller to emulate Rails load order

  include Rails.application.routes.url_helpers
  include QBWC::Controller
end

QBWC_EMPTY_RESPONSE = "<?xml version=\"1.0\"?>\r
    <?qbxml version=\"7.0\"?>\r
    <QBXML>\r
      <QBXMLMsgsRs onError=\"stopOnError\">\r
      </QBXMLMsgsRs>\r
    </QBXML>\r"

QBWC_CUSTOMER_ADD_RQ = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\r
    <?qbxml version=\"7.0\"?>\r
    <QBXML>\r
      <QBXMLMsgsRq onError = \"stopOnError\">\r
        <CustomerAddRq>\r
          <CustomerAdd>\r
            <Name>#{QBWC_USERNAME}</Name>\r
          </CustomerAdd>\r
        </CustomerAddRq>\r
      </QBXMLMsgsRq>\r
    </QBXML>\r"

QBWC_CUSTOMER_ADD_RQ_LONG = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\r
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

QBWC_CUSTOMER_ADD_RESPONSE_LONG = "<?xml version=\"1.0\" ?><QBXML><QBXMLMsgsRs><CustomerAddRs statusCode=\"0\" statusSeverity=\"Info\" statusMessage=\"Status OK\"><CustomerRet><ListID>8000001B-1405768916</ListID><TimeCreated>2014-07-19T07:21:56-05:00</TimeCreated><TimeModified>2014-07-19T07:21:56-05:00</TimeModified><EditSequence>1405768916</EditSequence><Name>mrjoecustomer</Name><FullName>Joseph Customer</FullName><IsActive>true</IsActive><Sublevel>0</Sublevel><CompanyName>Joes Garage</CompanyName><Salutation>Mr</Salutation><FirstName>Joe</FirstName><LastName>Customer</LastName><BillAddress><Addr1>123 Main St.</Addr1><City>Mountain View</City><State>CA</State><PostalCode>94566</PostalCode></BillAddress><Email>joecustomer@gmail.com</Email><Balance>0.00</Balance><TotalBalance>0.00</TotalBalance><AccountNumber>89087</AccountNumber><CreditLimit>2000.00</CreditLimit><JobStatus>None</JobStatus></CustomerRet></CustomerAddRs></QBXMLMsgsRs></QBXML>"

QBWC_CUSTOMER_QUERY_RQ = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\r
    <?qbxml version=\"7.0\"?>\r
    <QBXML>\r
      <QBXMLMsgsRq onError = \"stopOnError\">\r
        <CustomerQueryRq>\r
          <FullName>#{QBWC_USERNAME}</FullName>\r
        </CustomerQueryRq>\r
      </QBXMLMsgsRq>\r
    </QBXML>\r"

QBWC_CUSTOMER_QUERY_RESPONSE_INFO = "<?xml version=\"1.0\" ?><QBXML><QBXMLMsgsRs><CustomerQueryRs statusCode=\"0\" statusSeverity=\"Info\" statusMessage=\"Status OK\"><CustomerRet><ListID>8000001B-1405777862</ListID><TimeCreated>2014-07-30T21:11:20-05:00</TimeCreated><TimeModified>2005-07-30T21:11:20-05:00</TimeModified><EditSequence>1405777862</EditSequence><Name>#{QBWC_USERNAME}</Name><Salutation>Mr</Salutation><FullName>#{QBWC_USERNAME}</FullName><IsActive>true</IsActive><Sublevel>0</Sublevel><Email>#{QBWC_USERNAME}@gmail.com</Email><Balance>0.00</Balance><TotalBalance>0.00</TotalBalance><AccountNumber>123456789</AccountNumber><JobStatus>None</JobStatus></CustomerRet></CustomerQueryRs></QBXMLMsgsRs></QBXML>"

QBWC_CUSTOMER_QUERY_STATUS_MESSAGE_WARN = 'The query request has not been fully completed. There was a required element ("bleech") that could not be found in QuickBooks.'

QBWC_CUSTOMER_QUERY_RESPONSE_WARN = "<?xml version=\"1.0\" ?><QBXML><QBXMLMsgsRs><CustomerQueryRs statusCode=\"500\" statusSeverity=\"Warn\" statusMessage=\"The query request has not been fully completed. There was a required element (&quot;bleech&quot;) that could not be found in QuickBooks.\" /></QBXMLMsgsRs></QBXML>"

QBWC_CUSTOMER_QUERY_STATUS_MESSAGE_ERROR = 'Object "8000001B-1405768916" specified in the request cannot be found.  QuickBooks error message: Invalid argument.  The specified record does not exist in the list.'

QBWC_CUSTOMER_QUERY_RESPONSE_ERROR = "<?xml version=\"1.0\" ?><QBXML><QBXMLMsgsRs><CustomerQueryRs statusCode=\"3120\" statusSeverity=\"Error\" statusMessage=\"Object &quot;8000001B-1405768916&quot; specified in the request cannot be found.  QuickBooks error message: Invalid argument.  The specified record does not exist in the list.\" /></QBXMLMsgsRs></QBXML>"

AUTHENTICATE_PARAMS = {
  :strUserName => QBWC_USERNAME,
  :strPassword => QBWC_PASSWORD,
  :@xmlns      => "http://developer.intuit.com/"
}

AUTHENTICATE_SOAP_ACTION = :authenticate
AUTHENTICATE_WASH_OUT_SOAP_DATA = {
  :Envelope => {
    :Body => { AUTHENTICATE_SOAP_ACTION => AUTHENTICATE_PARAMS },
    :"@xmlns:soap" => "http://schemas.xmlsoap.org/soap/envelope/",
    :"@xmlns:xsi"  => "http://www.w3.org/2001/XMLSchema-instance",
    :"@xmlns:xsd"  => "http://www.w3.org/2001/XMLSchema"
  }
}

SERVER_VERSION_PARAMS = {
  :@xmlns      => "http://developer.intuit.com/"
}

SERVER_VERSION_SOAP_ACTION = :serverVersion

SEND_REQUEST_PARAMS = {
  :qbXMLCountry   => "US",
  :qbXMLMajorVers => "13",
  :qbXMLMinorVers => "0",
  :ticket         => "acc277c2d9351c6da12345887293fc6a32860006",
  :strHCPResponse => "<?xml version=\"1.0\" ?><QBXML><QBXMLMsgsRs><HostQueryRs requestID=\"0\" statusCode=\"0\" statusSeverity=\"Info\" statusMessage=\"Status OK\"><HostRet><ProductName>QuickBooks Pro 2014</ProductName><MajorVersion>24</MajorVersion><MinorVersion>0</MinorVersion><Country>US</Country><SupportedQBXMLVersion>1.0</SupportedQBXMLVersion><SupportedQBXMLVersion>1.1</SupportedQBXMLVersion><SupportedQBXMLVersion>2.0</SupportedQBXMLVersion><SupportedQBXMLVersion>2.1</SupportedQBXMLVersion><SupportedQBXMLVersion>3.0</SupportedQBXMLVersion><SupportedQBXMLVersion>4.0</SupportedQBXMLVersion><SupportedQBXMLVersion>4.1</SupportedQBXMLVersion><SupportedQBXMLVersion>5.0</SupportedQBXMLVersion><SupportedQBXMLVersion>6.0</SupportedQBXMLVersion><SupportedQBXMLVersion>7.0</SupportedQBXMLVersion><SupportedQBXMLVersion>8.0</SupportedQBXMLVersion><SupportedQBXMLVersion>9.0</SupportedQBXMLVersion><SupportedQBXMLVersion>10.0</SupportedQBXMLVersion><SupportedQBXMLVersion>11.0</SupportedQBXMLVersion><SupportedQBXMLVersion>12.0</SupportedQBXMLVersion><SupportedQBXMLVersion>13.0</SupportedQBXMLVersion><IsAutomaticLogin>false</IsAutomaticLogin><QBFileMode>SingleUser</QBFileMode></HostRet></HostQueryRs><CompanyQueryRs requestID=\"1\" statusCode=\"0\" statusSeverity=\"Info\" statusMessage=\"Status OK\"><CompanyRet><IsSampleCompany>false</IsSampleCompany><CompanyName>myCompany</CompanyName><LegalCompanyName>myCompany Legal Name</LegalCompanyName><Address><City>P.O. Box 12345</City><State>CA</State><PostalCode>12345</PostalCode><Country>US</Country></Address><AddressBlock><Addr1>P.O. Box 12345</Addr1><Addr2>CA 12345</Addr2></AddressBlock><LegalAddress><Addr1>P.O. Box 12345</Addr1><City>Anytown</City><State>CA</State><PostalCode>12345</PostalCode><Country>US</Country></LegalAddress><Phone>800-123-4567</Phone><Email>myname@mydomain.com</Email><FirstMonthFiscalYear>January</FirstMonthFiscalYear><FirstMonthIncomeTaxYear>January</FirstMonthIncomeTaxYear><CompanyType>InformationTechnologyComputersSoftware</CompanyType><EIN>12-3456789</EIN><TaxForm>Form1120</TaxForm><SubscribedServices><Service><Name>QuickBooks Online Banking</Name><Domain>banking.qb</Domain><ServiceStatus>Never</ServiceStatus></Service><Service><Name>QuickBooks Online Billing</Name><Domain>billing.qb</Domain><ServiceStatus>Never</ServiceStatus></Service><Service><Name>QuickBooks Online Billing Level 1 Service</Name><Domain>qbob1.qbn</Domain><ServiceStatus>Never</ServiceStatus></Service><Service><Name>QuickBooks Online Billing Level 2 Service</Name><Domain>qbob2.qbn</Domain><ServiceStatus>Never</ServiceStatus></Service><Service><Name>QuickBooks Online Billing Payment Service</Name><Domain>qbobpay.qbn</Domain><ServiceStatus>Never</ServiceStatus></Service><Service><Name>QuickBooks Bill Payment</Name><Domain>billpay.qb</Domain><ServiceStatus>Never</ServiceStatus></Service><Service><Name>QuickBooks Online Billing Paper Mailing Service</Name><Domain>qbobpaper.qbn</Domain><ServiceStatus>Never</ServiceStatus></Service><Service><Name>QuickBooks Payroll Service</Name><Domain>payroll.qb</Domain><ServiceStatus>Never</ServiceStatus></Service><Service><Name>QuickBooks Basic Payroll Service</Name><Domain>payrollbsc.qb</Domain><ServiceStatus>Never</ServiceStatus></Service><Service><Name>QuickBooks Basic Disk Payroll Service</Name><Domain>payrollbscdisk.qb</Domain><ServiceStatus>Never</ServiceStatus></Service><Service><Name>QuickBooks Deluxe Payroll Service</Name><Domain>payrolldlx.qb</Domain><ServiceStatus>Never</ServiceStatus></Service><Service><Name>QuickBooks Premier Payroll Service</Name><Domain>payrollprm.qb</Domain><ServiceStatus>Never</ServiceStatus></Service><Service><Name>Basic Plus Federal</Name><Domain>basic_plus_fed.qb</Domain><ServiceStatus>Never</ServiceStatus></Service><Service><Name>Basic Plus Federal and State</Name><Domain>basic_plus_fed_state.qb</Domain><ServiceStatus>Never</ServiceStatus></Service><Service><Name>Basic Plus Direct Deposit</Name><Domain>basic_plus_dd.qb</Domain><ServiceStatus>Never</ServiceStatus></Service><Service><Name>Merchant Account Service</Name><Domain>mas.qbn</Domain><ServiceStatus>Never</ServiceStatus></Service></SubscribedServices><AccountantCopy><AccountantCopyExists>false</AccountantCopyExists></AccountantCopy><DataExtRet><OwnerID>{512349B1-1111-2222-3333-000DE1813D20}</OwnerID><DataExtName>AppLock</DataExtName><DataExtType>STR255TYPE<yzer/DataExtType><DataExtValue>LOCKED:REDACTED:631234599990000223</DataExtValue></DataExtRet><DataExtRet><OwnerID>{512349B1-1111-2222-3333-000DE1813D20}</OwnerID><DataExtName>FileID</DataExtName><DataExtType>STR255TYPE</DataExtType><DataExtValue>{00000ee-1111-ffff-cccc-5ff123456047}</DataExtValue></DataExtRet></CompanyRet></CompanyQueryRs><PreferencesQueryRs requestID=\"2\" statusCode=\"0\" statusSeverity=\"Info\" statusMessage=\"Status OK\"><PreferencesRet><AccountingPreferences><IsUsingAccountNumbers>false</IsUsingAccountNumbers><IsRequiringAccounts>true</IsRequiringAccounts><IsUsingClassTracking>false</IsUsingClassTracking><IsUsingAuditTrail>true</IsUsingAuditTrail><IsAssigningJournalEntryNumbers>true</IsAssigningJournalEntryNumbers></AccountingPreferences><FinanceChargePreferences><AnnualInterestRate>0.00</AnnualInterestRate><MinFinanceCharge>0.00</MinFinanceCharge><GracePeriod>0</GracePeriod><IsAssessingForOverdueCharges>false</IsAssessingForOverdueCharges><CalculateChargesFrom>DueDate</CalculateChargesFrom><IsMarkedToBePrinted>false</IsMarkedToBePrinted></FinanceChargePreferences><JobsAndEstimatesPreferences><IsUsingEstimates>true</IsUsingEstimates><IsUsingProgressInvoicing>false</IsUsingProgressInvoicing><IsPrintingItemsWithZeroAmounts>false</IsPrintingItemsWithZeroAmounts></JobsAndEstimatesPreferences><MultiCurrencyPreferences><IsMultiCurrencyOn>false</IsMultiCurrencyOn></MultiCurrencyPreferences><MultiLocationInventoryPreferences><IsMultiLocationInventoryAvailable>false</IsMultiLocationInventoryAvailable><IsMultiLocationInventoryEnabled>false</IsMultiLocationInventoryEnabled></MultiLocationInventoryPreferences><PurchasesAndVendorsPreferences><IsUsingInventory>false</IsUsingInventory><DaysBillsAreDue>10</DaysBillsAreDue><IsAutomaticallyUsingDiscounts>false</IsAutomaticallyUsingDiscounts></PurchasesAndVendorsPreferences><ReportsPreferences><AgingReportBasis>AgeFromDueDate</AgingReportBasis><SummaryReportBasis>Accrual</SummaryReportBasis></ReportsPreferences><SalesAndCustomersPreferences><IsTrackingReimbursedExpensesAsIncome>false</IsTrackingReimbursedExpensesAsIncome><IsAutoApplyingPayments>true</IsAutoApplyingPayments><PriceLevels><IsUsingPriceLevels>true</IsUsingPriceLevels><IsRoundingSalesPriceUp>true</IsRoundingSalesPriceUp></PriceLevels></SalesAndCustomersPreferences><TimeTrackingPreferences><FirstDayOfWeek>Monday</FirstDayOfWeek></TimeTrackingPreferences><CurrentAppAccessRights><IsAutomaticLoginAllowed>false</IsAutomaticLoginAllowed><IsPersonalDataAccessAllowed>false</IsPersonalDataAccessAllowed></CurrentAppAccessRights><ItemsAndInventoryPreferences><EnhancedInventoryReceivingEnabled>false</EnhancedInventoryReceivingEnabled><IsTrackingSerialOrLotNumber>None</IsTrackingSerialOrLotNumber><FIFOEnabled>false</FIFOEnabled><IsRSBEnabled>false</IsRSBEnabled><IsBarcodeEnabled>false</IsBarcodeEnabled></ItemsAndInventoryPreferences></PreferencesRet></PreferencesQueryRs></QBXMLMsgsRs></QBXML>", 
}

SEND_REQUEST_SOAP_ACTION = :sendRequestXML


RECEIVE_RESPONSE_PARAMS = {
  :ticket   => "60676ae302a35ead77c81b16993ef073ff3c930e",
  :response => "<?xml version=\"1.0\" ?><QBXML><QBXMLMsgsRs><CustomerAddRs statusCode=\"0\" statusSeverity=\"Info\" statusMessage=\"Status OK\"><CustomerRet><ListID>8000007B-1420967073</ListID><TimeCreated>2015-02-03T07:49:33-05:00</TimeCreated><TimeModified>2015-02-03T07:49:33-05:00</TimeModified><EditSequence>1420967073</EditSequence><Name>mrjoecustomer</Name><FullName>Joseph Customer</FullName><IsActive>true</IsActive><Sublevel>0</Sublevel><Email>joecustomer@gmail.com</Email><Balance>0.00</Balance><TotalBalance>0.00</TotalBalance><AccountNumber>8</AccountNumber><JobStatus>None</JobStatus></CustomerRet></CustomerAddRs></QBXMLMsgsRs></QBXML>", 
  :hresult => nil,
  :message => nil}

RECEIVE_RESPONSE_ERROR_PARAMS = {
  :ticket   => "40fddf910fa903bde3caee77da7b30ab0bc90804",
  :response => nil,
  :hresult  => "0x80040400",
  :message  => "QuickBooks found an error when parsing the provided XML text stream."
}

RECEIVE_RESPONSE_SOAP_ACTION = :receiveResponseXML

#-------------------------------------------
def _controller_env_is_required?
  # qbwc requires minimum wash_out 0.10.0
  # wash_out 0.10.0 uses controller env
  # wash_out 0.11.0 uses request.env
  WashOut::VERSION == "0.10.0"
end

#-------------------------------------------
def _set_controller_env_if_required
  if _controller_env_is_required?
    @controller.set_request!(@request) if Rails::VERSION::MAJOR >= 5
    @controller.env["wash_out.soap_data"] = @request.env["wash_out.soap_data"]
  end
end

#-------------------------------------------
def _simulate_soap_request(http_action, soap_action, soap_params)

  session = QBWC::ActiveRecord::Session::QbwcSession.first
  unless session.blank?
    ticket = session.ticket
    soap_params = soap_params.update(:ticket => ticket)
  end

  wash_out_soap_data = { :Envelope => { :Body => { soap_action => soap_params }}}

  # http://twobitlabs.com/2010/09/setting-request-headers-in-rails-functional-tests/
  @request.env["wash_out.soap_action"]  = soap_action.to_s
  @request.env["wash_out.soap_data"]    = wash_out_soap_data
  _set_controller_env_if_required

  if Rails::VERSION::MAJOR <= 4
    post http_action, use_route: :qbwc_action
  else
    post http_action, params: { use_route: :qbwc_action }
  end

end

#-------------------------------------------
def _authenticate
  # http://twobitlabs.com/2010/09/setting-request-headers-in-rails-functional-tests/
  @request.env["wash_out.soap_action"]  = AUTHENTICATE_SOAP_ACTION.to_s
  @request.env["wash_out.soap_data"]    = AUTHENTICATE_WASH_OUT_SOAP_DATA
  _set_controller_env_if_required

  process(:authenticate)
end

#-------------------------------------------
def _authenticate_with_queued_job
  # Queue a job
  QBWC.add_job(:customer_add_rq_job, true, COMPANY, QBWC::Worker)

  _authenticate
end

#-------------------------------------------
def _authenticate_wrong_password
  # deep copy
  bad_password_soap_data = Marshal.load(Marshal.dump(AUTHENTICATE_WASH_OUT_SOAP_DATA))
  bad_password_soap_data[:Envelope][:Body][AUTHENTICATE_SOAP_ACTION][:strPassword] = 'something wrong'
  @request.env["wash_out.soap_action"]  = AUTHENTICATE_SOAP_ACTION.to_s
  @request.env["wash_out.soap_data"]    = bad_password_soap_data
  _set_controller_env_if_required

  process(:authenticate)
end

#-------------------------------------------
def simulate_response(session, response=QBWC_EMPTY_RESPONSE)
  session.response = response
end
