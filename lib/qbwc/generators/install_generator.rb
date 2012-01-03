module QBWC
  module Generators
    class InstallGenerator < Rails::Generators::Base
      namespace "qbwc"
      desc "Copy Quickbooks Web Connector default files"
      source_root File.expand_path('../templates', __FILE__)

      def copy_config
         template('templates/qbwc_controller.rb', "app/controllers/qbwc_controller.rb")
      end

      def copy_controller
         template('templates/qbwc_controller.rb', "config/initializers/qbwc.rb")
      end
      
      def setup_routes
        route("match 'apis/quickbooks/:action', :controller => 'qbwc', :as => 'quickbooks'")
      end
      
    end
  end
end