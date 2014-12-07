$:<< File.expand_path(File.dirname(__FILE__) + '/../..')  # (for wash_out_helper.rb)
require 'test_helper.rb'

# http://pivotallabs.com/writing-rails-engine-rspec-controller-tests/
# http://jkamenik.github.io/blog/2014/02/07/controller-test-in-rails-engines/
# https://www.honeybadger.io/blog/2014/01/28/rails4-engine-controller-specs
class QBWCControllerTest < ActionController::TestCase

  def setup
    @routes = Rails.application.routes  # https://github.com/blowmage/minitest-rails/issues/133#issuecomment-36401436
    @controller = QbwcController.new    # http://stackoverflow.com/a/7743176
  end

  test "qwc" do
    #_inspect_routes
    get 'qwc', use_route: :qbwc_qwc

    assert_match /QBWCXML/,                                                 @response.body
    assert_match /AppName.*QbwcTestApplication development.*AppName/,       @response.body
    assert_match /AppURL.*http:\/\/test.host\/qbwc\/action.*AppURL/,        @response.body
    assert_match /AppDescription.*Quickbooks integration.*AppDescription/,  @response.body
    assert_match /AppSupport.*https:\/\/test.host\/.*AppSupport/,           @response.body
    assert_match /UserName.*foo.*UserName/,                                 @response.body
  end

end
