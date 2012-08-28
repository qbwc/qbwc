require 'rails/generators'

module Qbwc
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
        route("match 'apis/quickbooks/:action', :controller => 'qbwc', :as => 'quickbooks'")
      end
      
    end
  end
end