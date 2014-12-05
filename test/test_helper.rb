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
  end

end

QbwcTestApplication::Application.routes.draw do

  # Add these routes:
  # qbwc_wsdl   GET        /qbwc/wsdl              qbwc#_generate_wsdl
  # qbwc_action GET|POST   /qbwc/action            #<WashOut::Router:0x00000005cf46d0 @controller_name="QbwcController">
  wash_out :qbwc

  # Manually stub these generated routes:
  #          GET        /qbwc/action(.:format)  qbwc#_generate_wsdl
  # qbwc_qwc GET        /qbwc/qwc(.:format)     qbwc#qwc
  get 'qbwc/action' => 'qbwc#_generate_wsdl'
  get 'qbwc/qwc'    => 'qbwc#qwc',            :as => :qbwc_qwc

  # Route needed for test_qwc 
  get 'qbwc/action' => 'qbwc#action'

  # Stub a root route
  root :to => "qbwc#qwc"
end

class QbwcController < ActionController::Base
  include Rails.application.routes.url_helpers
  include QBWC::Controller
end


