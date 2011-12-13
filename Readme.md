Getting it to work:

1. Add a working version of soap4r to your Gemfile

  * gem 'rubyjedi-soap4r', '1.5.8.20100619003610'

2. Place the qbwc directory in your application's lib/ and make sure qbwc.rb gets loaded
during initialization

3. create a controller and route for qbwc to hit on every request

  ```ruby  
    class QbwcController < ApplicationController
      def show
        render :text => "This is a SOAP Server"
      end

      def create
        req = request
        res = QBWC::Interface.route_request(req)
        render :xml => res, :content_type => 'text/xml'
      end
    end
  ```

4. Edit soap_wrapper/default_servant.rb
  *  change credentials in the #authenticate method
  *  take a look at sendRequestXML and receiveResponseXML to see how the Session class is used

5. edit templates.rb
  *  the #quickbooks_sync method should return [parser, request_array], request
     array should contain all requests you want Quickbooks to process. Every
     request is an array which contains [raw qbxml, response proc]. QBWC::Session
     has everything you need to understand how it works.
