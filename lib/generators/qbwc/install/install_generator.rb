require 'rails/generators'

module QBWC
  module Generators
    class InstallGenerator < Rails::Generators::Base
      namespace "qbwc:install"
      desc "Copy Quickbooks Web Connector default files"
      source_root File.expand_path('../templates', __FILE__)
      
      def copy_config
         template('config/qbwc.rb', "config/initializers/qbwc.rb")
      end

      def copy_controller 
         template('controllers/qbwc_controller.rb', "app/controllers/qbwc_controller.rb")
      end

      def setup_routes
        route("get 'quickbooks/qwc' => 'quickbooks#qwc'")
        route("get 'quickbooks/action' => 'quickbooks#_generate_wsdl'")
        route("wash_out :quickbooks")
      end
      
    end
  end
end
