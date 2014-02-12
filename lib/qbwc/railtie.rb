require 'wash_out'

module QBWC
  class Railtie < ::Rails::Railtie
    config.wash_out.parser = :nokogiri
    config.wash_out.namespace = 'http://developer.intuit.com/'
  end
end
