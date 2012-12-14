# Quickbooks Web Connector (QBWC)

QBWC was designed to add quickbooks web connector integration to your Rails 3 application. 

* Implementation of the Soap WDSL spec for Intuit Quickbooks and Point of Sale
* Integration with a qbxml [parser](https://github.com/skryl/qbxml)

## Installation

Install the gem

  `gem install qbwc`

Add it to your Gemfile

  `gem "qbwc"`

Run the generator:

  `rails generate qbwc:install`

## Configuration


## Basics

The QBWC gem provides a in-memory work queue for the Quickbooks Web Connector to
interact with. This queue is comprised of a session, which takes care of the
queueing and persistence across web requests, the job(s), which are groupings of
similar requests along with a response processor, and the request(s) themselves,
which can be supplied in either raw XML or hash format.

### The Session

Every time the Web Connector initiates a new connection to your application, an
existing session will be found or a new one will be created. Upon creation, the
session will automatically round up all requests across currently enabled jobs
and queue them for processing. The session will persist across web requests until 
the work it contains has been exhausted.

### The Job

A Job groups similar requests together into a manageable work unit. It is
comprised of one or more requests and a response processor. The response
processor will be used to digest responses to all the requests in the job. A job
can 

The result of the code block is not cached and is re-evaluated every time a new
session is initiated. Only requests from enabled jobs are added to a new
session.

An optional response processor block can also be added to a job. Responses to
all requests are either processed immediately after being received or saved for
processing after the web connector closes its connection. The delayed processing
configuration option decides this.

### The Request

All requests in hash form must be generated or validated by the [qbxml](https://github.com/skryl/qbxml) gem.

  * A single qbxml request (String)
  * An array of qbxml requests (String)
  * A single qbxml request (Hash)
  * An array of qbxml requests (Hash)
  * Code that genrates a qbxml request
  * Code that generates an array of qbxml requests

Here is the rough order in which things happen:

  1. The Web Connector initiates a connection
  2. A new Session is created (with work from all enabled jobs)
  3. The web connector requests work
  4. The session responds with the next request in the work queue
  5. The web connector provides a response
  6. The session responds with the current progress of the work queue (0 - 100)
  6. The response is processed or saved for later processing
  7. If progress == 100 then the web connector closes the connection, otherwise goto 3
  8. Saved responses are processed if any exist


## Usage

### QBWC
Getting a list of enabled jobs from QBWC

```ruby
QBWC.enabled_jobs
```

### Adding Jobs

Create a new job

    QBWC.add_job('my job') do
      # work to do
    end

Add a response proc

    QBWC.jobs['my job'].set_response_proc do |r|
      # response processing work here
    end

Caveats
  * Jobs are enabled by default
  * Using a non unique job name will overwrite the existing job

### Managing Jobs

Jobs can be added, removed, enabled, and disabled. See the above section for
details on adding new jobs. 

Removing jobs is as easy as deleting them from the jobs hash.                   

    QBWC.jobs.delete('my job')

Disabling a job

    QBWC.jobs['my job'].disable

Enabling a job

    QBWC.jobs['my job'].enable

### Sample Jobs

Add a Customer (Wrapped)

          {  :qbxml_msgs_rq => 
            [
              {
                :xml_attributes =>  { "onError" => "stopOnError"}, 
                :customer_add_rq => 
                [
                  {
                    :xml_attributes => {"requestID" => "1"},  ##Optional
                    :customer_add   => { :name => "GermanGR" }
                  } 
                ] 
              }
            ]
          }
          
Add a Customer (Unwrapped)

        {
          :customer_add_rq    => 
          [
            {
              :xml_attributes => {"requestID" => "1"},  ##Optional
              :customer_add   => { :name => "GermanGR" }
            } 
          ] 
        }

Get All Vendors (In Chunks of 5)

        QBWC.add_job(:import_vendors) do
          [
            :vendor_query_rq  =>
            {
              :xml_attributes => { "requestID" =>"1", 'iterator'  => "Start" },
      
              :max_returned => 5,
              :owner_id => 0,
              :from_modified_date=> "1984-01-29T22:03:19"

            }
          ]
        end
        
Get All Vendors (Raw QBXML)

        QBWC.add_job(:import_vendors) do
          '<QBXML>
            <QBXMLMsgsRq onError="continueOnError">
            <VendorQueryRq requestID="6" iterator="Start">
            <MaxReturned>5</MaxReturned>
            <FromModifiedDate>1984-01-29T22:03:19-05:00</FromModifiedDate>
            <OwnerID>0</OwnerID>
          </VendorQueryRq>
          </QBXMLMsgsRq>
          </QBXML>
          '
        end

## Contributing to qbwc
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.
