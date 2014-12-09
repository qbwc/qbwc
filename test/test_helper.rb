# http://stackoverflow.com/a/4402193
require 'bundler/setup'
Bundler.setup

require 'minitest/autorun'

require 'active_support'
require 'active_record'
require 'action_controller'
require 'rails'

$:<< File.expand_path(File.dirname(__FILE__) + '/../lib')
require 'qbwc'
require 'qbwc/controller'
require 'qbwc/active_record'

COMPANY = ''
QBWC.api = :qb

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
    end
    ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
    require '../qbwc/lib/generators/qbwc/install/templates/db/migrate/create_qbwc_jobs'
    require '../qbwc/lib/generators/qbwc/install/templates/db/migrate/create_qbwc_sessions'
    ActiveRecord::Migration.run(CreateQbwcJobs)
    ActiveRecord::Migration.run(CreateQbwcSessions)
    QBWC.logger = Logger.new('/dev/null') # or STDOUT
  end

end

QbwcTestApplication::Application.routes.draw do

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

  # Stub a root route
  root :to => "qbwc#qwc"
end

class QbwcController < ActionController::Base
  include Rails.application.routes.url_helpers
  include QBWC::Controller
end

QBWC_USERNAME = 'myUserName'
QBWC_PASSWORD = 'myPassword'

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

SEND_REQUEST_PARAMS = {
  :qbXMLCountry   => "US",
  :qbXMLMajorVers => "13",
  :qbXMLMinorVers => "0",
  :ticket         => "acc277c2d9351c6da12345887293fc6a32860006",
  :strHCPResponse => "<?xml version=\"1.0\" ?><QBXML><QBXMLMsgsRs><HostQueryRs requestID=\"0\" statusCode=\"0\" statusSeverity=\"Info\" statusMessage=\"Status OK\"><HostRet><ProductName>QuickBooks Pro 2014</ProductName><MajorVersion>24</MajorVersion><MinorVersion>0</MinorVersion><Country>US</Country><SupportedQBXMLVersion>1.0</SupportedQBXMLVersion><SupportedQBXMLVersion>1.1</SupportedQBXMLVersion><SupportedQBXMLVersion>2.0</SupportedQBXMLVersion><SupportedQBXMLVersion>2.1</SupportedQBXMLVersion><SupportedQBXMLVersion>3.0</SupportedQBXMLVersion><SupportedQBXMLVersion>4.0</SupportedQBXMLVersion><SupportedQBXMLVersion>4.1</SupportedQBXMLVersion><SupportedQBXMLVersion>5.0</SupportedQBXMLVersion><SupportedQBXMLVersion>6.0</SupportedQBXMLVersion><SupportedQBXMLVersion>7.0</SupportedQBXMLVersion><SupportedQBXMLVersion>8.0</SupportedQBXMLVersion><SupportedQBXMLVersion>9.0</SupportedQBXMLVersion><SupportedQBXMLVersion>10.0</SupportedQBXMLVersion><SupportedQBXMLVersion>11.0</SupportedQBXMLVersion><SupportedQBXMLVersion>12.0</SupportedQBXMLVersion><SupportedQBXMLVersion>13.0</SupportedQBXMLVersion><IsAutomaticLogin>false</IsAutomaticLogin><QBFileMode>SingleUser</QBFileMode></HostRet></HostQueryRs><CompanyQueryRs requestID=\"1\" statusCode=\"0\" statusSeverity=\"Info\" statusMessage=\"Status OK\"><CompanyRet><IsSampleCompany>false</IsSampleCompany><CompanyName>myCompany</CompanyName><LegalCompanyName>myCompany Legal Name</LegalCompanyName><Address><City>P.O. Box 12345</City><State>CA</State><PostalCode>12345</PostalCode><Country>US</Country></Address><AddressBlock><Addr1>P.O. Box 12345</Addr1><Addr2>CA 12345</Addr2></AddressBlock><LegalAddress><Addr1>P.O. Box 12345</Addr1><City>Anytown</City><State>CA</State><PostalCode>12345</PostalCode><Country>US</Country></LegalAddress><Phone>800-123-4567</Phone><Email>myname@mydomain.com</Email><FirstMonthFiscalYear>January</FirstMonthFiscalYear><FirstMonthIncomeTaxYear>January</FirstMonthIncomeTaxYear><CompanyType>InformationTechnologyComputersSoftware</CompanyType><EIN>12-3456789</EIN><TaxForm>Form1120</TaxForm><SubscribedServices><Service><Name>QuickBooks Online Banking</Name><Domain>banking.qb</Domain><ServiceStatus>Never</ServiceStatus></Service><Service><Name>QuickBooks Online Billing</Name><Domain>billing.qb</Domain><ServiceStatus>Never</ServiceStatus></Service><Service><Name>QuickBooks Online Billing Level 1 Service</Name><Domain>qbob1.qbn</Domain><ServiceStatus>Never</ServiceStatus></Service><Service><Name>QuickBooks Online Billing Level 2 Service</Name><Domain>qbob2.qbn</Domain><ServiceStatus>Never</ServiceStatus></Service><Service><Name>QuickBooks Online Billing Payment Service</Name><Domain>qbobpay.qbn</Domain><ServiceStatus>Never</ServiceStatus></Service><Service><Name>QuickBooks Bill Payment</Name><Domain>billpay.qb</Domain><ServiceStatus>Never</ServiceStatus></Service><Service><Name>QuickBooks Online Billing Paper Mailing Service</Name><Domain>qbobpaper.qbn</Domain><ServiceStatus>Never</ServiceStatus></Service><Service><Name>QuickBooks Payroll Service</Name><Domain>payroll.qb</Domain><ServiceStatus>Never</ServiceStatus></Service><Service><Name>QuickBooks Basic Payroll Service</Name><Domain>payrollbsc.qb</Domain><ServiceStatus>Never</ServiceStatus></Service><Service><Name>QuickBooks Basic Disk Payroll Service</Name><Domain>payrollbscdisk.qb</Domain><ServiceStatus>Never</ServiceStatus></Service><Service><Name>QuickBooks Deluxe Payroll Service</Name><Domain>payrolldlx.qb</Domain><ServiceStatus>Never</ServiceStatus></Service><Service><Name>QuickBooks Premier Payroll Service</Name><Domain>payrollprm.qb</Domain><ServiceStatus>Never</ServiceStatus></Service><Service><Name>Basic Plus Federal</Name><Domain>basic_plus_fed.qb</Domain><ServiceStatus>Never</ServiceStatus></Service><Service><Name>Basic Plus Federal and State</Name><Domain>basic_plus_fed_state.qb</Domain><ServiceStatus>Never</ServiceStatus></Service><Service><Name>Basic Plus Direct Deposit</Name><Domain>basic_plus_dd.qb</Domain><ServiceStatus>Never</ServiceStatus></Service><Service><Name>Merchant Account Service</Name><Domain>mas.qbn</Domain><ServiceStatus>Never</ServiceStatus></Service></SubscribedServices><AccountantCopy><AccountantCopyExists>false</AccountantCopyExists></AccountantCopy><DataExtRet><OwnerID>{512349B1-1111-2222-3333-000DE1813D20}</OwnerID><DataExtName>AppLock</DataExtName><DataExtType>STR255TYPE<yzer/DataExtType><DataExtValue>LOCKED:REDACTED:631234599990000223</DataExtValue></DataExtRet><DataExtRet><OwnerID>{512349B1-1111-2222-3333-000DE1813D20}</OwnerID><DataExtName>FileID</DataExtName><DataExtType>STR255TYPE</DataExtType><DataExtValue>{00000ee-1111-ffff-cccc-5ff123456047}</DataExtValue></DataExtRet></CompanyRet></CompanyQueryRs><PreferencesQueryRs requestID=\"2\" statusCode=\"0\" statusSeverity=\"Info\" statusMessage=\"Status OK\"><PreferencesRet><AccountingPreferences><IsUsingAccountNumbers>false</IsUsingAccountNumbers><IsRequiringAccounts>true</IsRequiringAccounts><IsUsingClassTracking>false</IsUsingClassTracking><IsUsingAuditTrail>true</IsUsingAuditTrail><IsAssigningJournalEntryNumbers>true</IsAssigningJournalEntryNumbers></AccountingPreferences><FinanceChargePreferences><AnnualInterestRate>0.00</AnnualInterestRate><MinFinanceCharge>0.00</MinFinanceCharge><GracePeriod>0</GracePeriod><IsAssessingForOverdueCharges>false</IsAssessingForOverdueCharges><CalculateChargesFrom>DueDate</CalculateChargesFrom><IsMarkedToBePrinted>false</IsMarkedToBePrinted></FinanceChargePreferences><JobsAndEstimatesPreferences><IsUsingEstimates>true</IsUsingEstimates><IsUsingProgressInvoicing>false</IsUsingProgressInvoicing><IsPrintingItemsWithZeroAmounts>false</IsPrintingItemsWithZeroAmounts></JobsAndEstimatesPreferences><MultiCurrencyPreferences><IsMultiCurrencyOn>false</IsMultiCurrencyOn></MultiCurrencyPreferences><MultiLocationInventoryPreferences><IsMultiLocationInventoryAvailable>false</IsMultiLocationInventoryAvailable><IsMultiLocationInventoryEnabled>false</IsMultiLocationInventoryEnabled></MultiLocationInventoryPreferences><PurchasesAndVendorsPreferences><IsUsingInventory>false</IsUsingInventory><DaysBillsAreDue>10</DaysBillsAreDue><IsAutomaticallyUsingDiscounts>false</IsAutomaticallyUsingDiscounts></PurchasesAndVendorsPreferences><ReportsPreferences><AgingReportBasis>AgeFromDueDate</AgingReportBasis><SummaryReportBasis>Accrual</SummaryReportBasis></ReportsPreferences><SalesAndCustomersPreferences><IsTrackingReimbursedExpensesAsIncome>false</IsTrackingReimbursedExpensesAsIncome><IsAutoApplyingPayments>true</IsAutoApplyingPayments><PriceLevels><IsUsingPriceLevels>true</IsUsingPriceLevels><IsRoundingSalesPriceUp>true</IsRoundingSalesPriceUp></PriceLevels></SalesAndCustomersPreferences><TimeTrackingPreferences><FirstDayOfWeek>Monday</FirstDayOfWeek></TimeTrackingPreferences><CurrentAppAccessRights><IsAutomaticLoginAllowed>false</IsAutomaticLoginAllowed><IsPersonalDataAccessAllowed>false</IsPersonalDataAccessAllowed></CurrentAppAccessRights><ItemsAndInventoryPreferences><EnhancedInventoryReceivingEnabled>false</EnhancedInventoryReceivingEnabled><IsTrackingSerialOrLotNumber>None</IsTrackingSerialOrLotNumber><FIFOEnabled>false</FIFOEnabled><IsRSBEnabled>false</IsRSBEnabled><IsBarcodeEnabled>false</IsBarcodeEnabled></ItemsAndInventoryPreferences></PreferencesRet></PreferencesQueryRs></QBXMLMsgsRs></QBXML>", 
}

SEND_REQUEST_SOAP_ACTION = :sendRequestXML

#-------------------------------------------
def _authenticate
  # http://twobitlabs.com/2010/09/setting-request-headers-in-rails-functional-tests/
  @request.env["wash_out.soap_action"]  = AUTHENTICATE_SOAP_ACTION.to_s
  @request.env["wash_out.soap_data"]    = AUTHENTICATE_WASH_OUT_SOAP_DATA
  @controller.env["wash_out.soap_data"] = @request.env["wash_out.soap_data"]

  post 'authenticate', use_route: :qbwc_action
end

#-------------------------------------------
def _authenticate_with_queued_job
  # Queue a job
  QBWC.add_job(:customer_add_rq_job, COMPANY, QBWC::Worker) do
    QBWC_CUSTOMER_ADD_RQ
  end

  _authenticate
end
