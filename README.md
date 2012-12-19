# Quickbooks Web Connector (QBWC)

QBWC adds [Quickbooks Web Connector](http://marketplace.intuit.com/webconnector/) integration to your Rails 3/4 application. 

* Simplified job queueing and response processing
* No-XML request generation and validation with [qbxml](https://github.com/skryl/qbxml)
* Support for custom job queue implementations
* Works with both Quickbooks and Quickbooks Point of Sale


## Installation

Install the gem

  `gem install qbwc`

Add it to your Gemfile

  `gem "qbwc"`

Run the generator:

  `rails generate qbwc:install`


## Basics


### The Job


### The Session


### The Request

A request is a chunk of XML that the Web Connector can process. Requests can be
formatted as raw XML or Ruby hashes. Requests can be easily generated and
validated using the [qbxml](https://github.com/skryl/qbxml) gem.


### Workflow Overview

This is the rough order in which things happen

1. The Web Connector initiates a connection with the application
2. An existing QBWC session is retrieved or a new one is created
3. The web connector requests work from the QBWC session
4. The session responds with the next request in the work queue
5. The web connector processes the query and replies with a result set
6. The session processes the result set and sends back the current progress of
   the work queue (0 - 100)
7. If the session is exhausted then the web connector closes the connection,
   otherwise it restarts from step 3


## Usage


### Managing Jobs


#### Listing Jobs

```ruby
QBWC.jobs
```

Listing all jobs that match a pattern

```ruby
QBWC.jobs(:name => /customer/)
```

Listing all automatically queued jobs

```ruby
QBWC.jobs(:auto => true)
```

Listing all disabled jobs

```ruby
QBWC.jobs(:enabled => false)
```

#### Adding Jobs

Adding a manual job

```ruby
QBWC.add_job :my_manual_job do |a, b|
  # qbxml request(s) here
end
```

Adding an automatic job

```ruby
QBWC.add_job :my_auto_job, :auto => true do
  # qbxml request(s) here
end
```

Add a response proccessor for a job

```ruby
QBWC.on_response :my_job do |r|
  # response processing here
end
```


#### Modifying an existing job

Changing job properties

```ruby
QBWC.mod_job :my_job, :auto => false, :enabled => false
```

Changing the job body

```ruby
QBWC.mod_job :my_job do |d|
  # qbxml request(s) here
end
```


#### Queueing jobs

Automatic jobs are queued every time a new session is created. Manual jobs have
to be queued when needed.

```ruby
QBWC.queue(:new_customers, Customer.all)
```


#### Job Configuration DSL

All of the above class methods are accessible in the configuration context of
the QBWC object, allowing you to keep all of your QBWC specific definitions in a
single, clean, configuration file.

```ruby
QBWC.configure do
  add_job :my_manual_job do
  end

  on_response :my_manual_job do
  end

  add_job :my_auto_job, :auto => true do
  end

  on_response :my_auto_job do
  end
end
```

Caveats

* Jobs are enabled by default
* Jobs are manual by default
* Using a non unique job name when creating a job will overwrite the job with
  the same name


### Sample Jobs

Create new customers

```ruby
QBWC.add_job :new_customers do |customers|
  Array(customers).map do |c|
    { xml_attributes:  { onError: "stopOnError"}, 
      customer_add_rq: {
        :xml_attributes: { requestID: "1"}
        :customer_add:   { name: c.name} } }
  end
end
```

```ruby
QBWC.on_response :new_customers do |c|
  
end
```

Get All Vendors

```ruby
QBWC.add_job :import_vendors, :auto => true do
%q(
  <QBXML>
    <QBXMLMsgsRq onError="continueOnError">
      <VendorQueryRq requestID="6" iterator="Start">
        <MaxReturned>5</MaxReturned>
        <FromModifiedDate>1984-01-29T22:03:19-05:00</FromModifiedDate>
        <OwnerID>0</OwnerID>
      </VendorQueryRq>
    </QBXMLMsgsRq>
  </QBXML>
)
end
```

```ruby
QBWC.on_response :new_customer do |v|
  
end
```


## Configuration

All configuration options can be set in the auto-generated initializers/qbwc.rb
file. The sample values below represent the default settings.

Set web connector authentication credentials

```ruby
c.username = "foo"
c.password = "bar"
```

Set company file path (blank for open or named path or function etc..)

```ruby
c.company_file_path = ""
```

Set minimum Quickbooks version

```ruby
c.min_version = 7.0
```

Set Quickbooks support URL provided

```ruby
c.support_site_url = "localhost:3000"
```

Set Quickbooks owner ID

```ruby
c.owner_id = '{57F3B9B1-86F1-4fcc-B1EE-566DE1813D20}'
```

In the event of an error in the communication process do you wish the sync to stop or blaze through

```ruby
Options: 
:stop
:continue

c.on_error = :stop
```

Enable logging of all requests and responses

```ruby
QBWC.logging = false
```

Select Quickbooks api to use

```ruby
# Options
# :qb
# :qbpos

c.api = :qb
```

Perform response processing after session termination. Enabling this option
will speed up qbwc session time (and potentially fix timeout issues) at the
expense of  memory since every response must be stored until it is
processed. 

```ruby
c.delayed_processing = false
```


## Contributing to qbwc
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.
