require 'qbwc/version'
require 'qbxml'

module QBWC

  # Web connector login credentials
  #
  mattr_accessor :username
  @@username = 'foo'
  
  mattr_accessor :password
  @@password = 'bar'
  
  # Full path to company file 
  #
  mattr_accessor :company_file_path 
  @@company_file_path = ""
  
  # Minimum quickbooks version required for use in qbxml requests
  #
  mattr_accessor :min_version
  @@min_version = 3.0
  
  # Quickbooks support url provided in qwc file
  #
  mattr_accessor :support_site_url
  @@support_site_url = 'http://google.com'
  
  # Quickbooks owner id provided in qwc file
  #
  mattr_accessor :owner_id
  @@owner_id = '{57F3B9B1-86F1-4fcc-B1EE-566DE1813D20}'
  
  # Job definitions
  #
  mattr_reader :jobs
  @@jobs = {}
  
  # OnError action
  #
  mattr_reader :on_error
  @@on_error = 'stopOnError'

  # Toggle delayed processing
  #
  mattr_accessor :delayed_processing
  @@delayed_processing = false

  # Quickbooks Type (either :qb or :qbpos)
  #
  mattr_reader :api, :parser
  @@api = :qb
  @@parser = Qbxml.new(@@api)
  
class << self

  def add_job(name, &block)
    @@jobs[name] = Job.new(name, &block)
  end

  def remove_job(name)
    @@jobs.delete(name)
  end

  def enabled_jobs
    @@jobs.select { |n, j| j.enabled? }
  end
  
  def on_error=(reaction)
    raise_if_enabled_jobs
    raise_if_invalid_option(:on_error, [:stop, :continue], reaction)

    @@on_error = \
      case reaction
      when :stop then "stopOnError" 
      when :continue then "continueOnError"
      end
  end
  
  def api=(api)
    raise_if_enabled_jobs
    raise_if_invalid_option(:api, [:qb, :qbpos], api)

    @@api = api
    @@parser = ::Qbxml.new(api) 
  end

  # Allow configuration overrides
  def configure
    yield self
  end

private

  def raise_if_enabled_jobs
    raise "This option cannot be changed when any jobs are enabled" if QBWC::Session.enabled_jobs?
  end

  def raise_if_invalid_option(name, valid_options, option)
    raise "#{name} must be #{valid_options.join(' or ')}" unless valid_options.include?(option)
  end

end
end

require 'fiber'

require_relative 'qbwc/soap_wrapper/default'
require_relative 'qbwc/soap_wrapper/defaultMappingRegistry'
require_relative 'qbwc/soap_wrapper/defaultServant'
require_relative 'qbwc/soap_wrapper/QBWebConnectorSvc'
require_relative 'qbwc/soap_wrapper'
require_relative 'qbwc/session'
require_relative 'qbwc/request'
require_relative 'qbwc/job'
