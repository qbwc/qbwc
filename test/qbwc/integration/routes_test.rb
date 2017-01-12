$:<< File.expand_path(File.dirname(__FILE__) + '/../..')
require 'test_helper.rb'

class RoutesTest < ActionDispatch::IntegrationTest

  def setup
    RoutesTest.app = Rails.application

    # Initialize sets view paths
    RoutesTest.app.initialize! unless RoutesTest.app.initialized?

    # Assign routes
    QbwcTestApplication::Application.routes.draw do
      _assign_routes
    end

    QBWC.clear_jobs
  end

  test "qwc" do
    #_inspect_routes
    get '/qbwc/qwc'

    assert_match(/QBWCXML/,                                                 @response.body)
    assert_match(Regexp.new("AppName.*QbwcTestApplication #{Rails.env}.*AppName"),       @response.body)
    assert_match(/AppURL.*http:\/\/www.example.com\/qbwc\/action.*AppURL/,  @response.body)
    assert_match(/AppDescription.*Quickbooks integration.*AppDescription/,  @response.body)
    assert_match(/AppSupport.*https:\/\/www.example.com\/.*AppSupport/,     @response.body)
    assert_match(/UserName.*#{QBWC_USERNAME}.*UserName/,        	    @response.body)
  end

  test "qbwc/action without soap returns successfully" do
    #_inspect_routes
    get '/qbwc/action'
    assert_response :success
  end

end
