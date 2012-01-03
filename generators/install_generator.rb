module QBWC
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc "Copy Quickbooks Web Connector default files"
      source_root File.expand_path('../templates', __FILE__)

      def copy_config
        directory 'config'
      end

      def copy_controller
        directory 'app/controllers'
      end
      
      def setup_routes
        route("add_routes")
      end
      
      def add_routes
        return match 'apis/quickbooks/:action', :controller => 'qbwc', :as => 'quickbooks'
      end
      
    end
  end
end