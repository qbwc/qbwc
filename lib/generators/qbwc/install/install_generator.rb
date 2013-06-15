require 'rails/generators'
require 'rails/generators/active_record'

module QBWC
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      extend ::ActiveRecord::Generators::Migration

      namespace "qbwc:install"
      desc "Copy Quickbooks Web Connector default files"
      source_root File.expand_path('../templates', __FILE__)
      argument :controller_name, :type => :string, :default => 'qbwc'
      
      def copy_config
         template('config/qbwc.rb', "config/initializers/qbwc.rb")
      end

      def copy_controller 
         template('controllers/qbwc_controller.rb', "app/controllers/#{controller_name}_controller.rb")
      end

      def active_record
        migration_template 'db/migrate/create_qbwc_jobs.rb'
        migration_template 'db/migrate/create_qbwc_sessions.rb'
      end

      def setup_routes
        route("get '#{controller_name}/qwc' => '#{controller_name}#qwc'")
        route("get '#{controller_name}/action' => '#{controller_name}#_generate_wsdl'")
        route("wash_out :#{controller_name}")
      end
      
    end
  end
end
