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
