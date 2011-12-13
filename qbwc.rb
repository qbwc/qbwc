#TODO: replace with ruby 1.9 external iterator

module QBWC; end

ROOT_PATH    = File.dirname(__FILE__)
LIB_PATH     = File.join(ROOT_PATH, 'lib')
LIB_FILES    = %w( soap_wrapper/default
                   soap_wrapper/defaultMappingRegistry 
                   soap_wrapper/defaultServant 
                   soap_wrapper/QBWebConnectorSvc 
                   interface templates session )
                   
LIB_FILES.each { |f| require File.join(LIB_PATH, f) }
