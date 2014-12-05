$:<< File.expand_path(File.dirname(__FILE__) + '/../..')  # (for wash_out_helper.rb)
require 'test_helper.rb'

class RoutesTest < ActionDispatch::IntegrationTest

  def setup
    RoutesTest.app = Rails.application
    Rails.logger = Logger.new('/dev/null')  # or STDOUT
  end

  test "qwc" do
    #_inspect_routes
    get 'qbwc/qwc'

    assert_match /QBWCXML/,                                                 @response.body
    assert_match /AppName.*QbwcTestApplication development.*AppName/,       @response.body
    assert_match /AppURL.*https:\/\/www.example.com\/qbwc\/action.*AppURL/, @response.body
    assert_match /AppDescription.*Quickbooks integration.*AppDescription/,  @response.body
    assert_match /AppSupport.*https:\/\/www.example.com\/.*AppSupport/,     @response.body
    assert_match /UserName.*foo.*UserName/,                                 @response.body
  end

  test "action" do
    #_inspect_routes
    get 'qbwc/action'
    assert_response :success
  end

end
