require 'rails/generators'
require 'rails/generators/active_record'

module QBWC
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      extend Rails::Generators::Migration

      namespace "qbwc:install"
      desc "Copy Quickbooks Web Connector default files"
      source_root File.expand_path('../templates', __FILE__)
      argument :controller_name, :type => :string, :default => 'qbwc'
      
      def routes_rb
         "config/routes.rb"
      end

      def copy_config
         template('config/qbwc.rb', "config/initializers/qbwc.rb")
      end

      def copy_controller 
         template('controllers/qbwc_controller.rb', "app/controllers/#{controller_name}_controller.rb")
      end

      def active_record
        migration_template 'db/migrate/create_qbwc_jobs.rb',     'db/migrate/create_qbwc_jobs.rb'
        migration_template 'db/migrate/create_qbwc_sessions.rb', 'db/migrate/create_qbwc_sessions.rb'
        migration_template 'db/migrate/index_qbwc_jobs.rb',      'db/migrate/index_qbwc_jobs.rb'
        migration_template 'db/migrate/change_request_index.rb', 'db/migrate/change_request_index.rb'
        migration_template 'db/migrate/session_pending_jobs_text.rb', 'db/migrate/session_pending_jobs_text.rb'
      end

      def self.next_migration_number(dirname)
        ::ActiveRecord::Generators::Base.next_migration_number(dirname)
      end

     def route1
        "wash_out :#{controller_name}"
     end

     def route2
        "get '#{controller_name}/qwc' => '#{controller_name}#qwc'"
     end

     def route3
        "get '#{controller_name}/action' => '#{controller_name}#_generate_wsdl'"
     end

     # Idempotent routes inspired by https://github.com/thoughtbot/administrate/issues/232
     # Idempotent routes fixed permanently by https://github.com/rails/rails/issues/22082
     def setup_routes
        route(route1) unless File.new(routes_rb).read.include?(route1)
        route(route2) unless File.new(routes_rb).read.include?(route2)
        route(route3) unless File.new(routes_rb).read.include?(route3)
      end
      
    end
  end
end
