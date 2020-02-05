$:<< File.expand_path(File.dirname(__FILE__) + '/../..')
require 'test_helper.rb'
require 'savon'

class SavonClientTest < ActionDispatch::IntegrationTest

  def setup
    SavonClientTest.app = Rails.application

    # Initialize sets view paths
    SavonClientTest.app.initialize! unless SavonClientTest.app.initialized?

    # Assign routes
    QbwcTestApplication::Application.routes.draw do
      _assign_routes
    end

    QBWC.clear_jobs
  end

  # http://blog.johnsonch.com/2013/04/18/rails-3-soap-and-testing-oh-my/
  test "qbwc/action serverVersion" do
    host     = 'www.example.com'
    url_base = "http://#{host}"
    url_path = '/qbwc/action'

    # http://httpirb.com/
    # https://github.com/savonrb/httpi
    HTTPI.adapter = :rack
    HTTPI::Adapter::Rack.mount(host, SavonClientTest.app)

    # https://github.com/savonrb/savon#usage-example
    # https://github.com/inossidabile/wash_out#usage
    client = Savon::Client.new({:wsdl => url_base + url_path })
    result = client.call(:server_version, :message => nil)

    # Use this assertion when QBWC::Controller.server_version_response returns nil
    if WashOut::VERSION == "0.10.0"
      assert_equal({:"@xsi:type"=>"xsd:string"}, result.body[:server_version_response][:server_version_result])
    else
      assert_nil result.body[:server_version_response][:server_version_result]
    end

    # Use this assertion when QBWC::Controller.server_version_response returns a value
    # assert_equal("SERVER_VERSION_RESPONSE", result.body[:server_version_response][:server_version_result])
  end

end
