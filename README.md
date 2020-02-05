QBWC lets your Rails application talk to QuickBooks Desktop.

[![Build Status](https://travis-ci.org/qbwc/qbwc.svg?branch=master)](https://travis-ci.org/qbwc/qbwc)

## Installation

`gem install qbwc`

Or add it to your Gemfile

`gem "qbwc"`

and run

`bundle install`

## Upgrade

Read [the changelog](CHANGELOG.md) if upgrading from previous versions.

## Configuration

Run the generator:

`rails generate qbwc:install`

Then the migrations:

`rake db:migrate`

Open `config/initializers/qbwc.rb` and check the settings there. (Re-)start your app.

Quickbooks *requires* HTTPS connections when connecting to remote machines. [ngrok](https://ngrok.com/) may be useful to fulfill this requirement.


### Authentication and multiple company files ###

If connecting to more than one company file or if you want different logins for different users, you can configure QBWC authentication. This is a `Proc` in `config/initializers/qbwc.rb` that accepts the username and password and returns the path to the QuickBooks company file to access:

```ruby
c.authenticator = Proc.new{|username, password|
  # qubert can access Oceanic
  next "C:\\QuickBooks\\Oceanic.QBW" if username == "qubert" && password == "brittany"
  # quimby can access Veridian
  next "C:\\QuickBooks\\Veridian.QBW" if username == "quimby" && password == "bethany"
  # no one else has access
  next nil
}
```

## QuickBooks configuration

Install [QuickBooks Web Connector](http://marketplace.intuit.com/webconnector/) on the machine that has QuickBooks installed.

For a single-user, single-company install, on the QuickBooks machine, visit the path /qbwc/qwc on your domain over an HTTPS connection. Download the file it provides. In QuickBooks Web Connector, click "Add an application", and pick the file. Give Quickbooks the password you specified in `config/initializers/qbwc.rb`.

At this point, QuickBooks Web Connector should be able to send requests to your app, but will have nothing to do, and say "No data exchange required".

### Multiple users and multiple company files ###

If you want to have more than one person to connect to the same QuickBooks company file, you will need to manually edit the QWC file to change the OwnerID (any GUID will do) before giving it to QuickBooks Web Connector.

If you want each person to have their own login, set up authentication per [Authentication and multiple company files](#authentication-and-multiple-company-files). In the QWC file, you will need to change `UserName`.

If you are connecting to multiple company files, you will additionally need to change `AppName` and `FileID` (any GUID) to be unique to each file. In the generated `QbwcController` you can override the `file_id` method to customize `FileID` and `app_name` to customize `AppName`.

## Creating jobs

QuickBooks Web Connector (the app you installed above) acts as the HTTP client, and your app acts as the HTTP server. To have QuickBooks perform tasks, you must add a qbwc job to your app, then get QuickBooks Web Connector to check your app for work to do.

To create a job (e.g. from `rails console` or wherever):

```ruby
require 'qbwc'
QBWC.add_job(:list_customers, true, 'C:\\QuickBooks\\Oceanic.QBW', CustomerTestWorker)
```

* The first argument is a unique name for the job. You can use this later to disable or delete the job.
* The second argument indicates whether the job is initially enabled.
* The third argument specifies the path to the QuickBooks company file this job affects.
* The fourth argument is your worker class. See the next section for a description of workers.

Your job will be persisted in your database and will remain active and run every time QuickBooks Web Connector runs an update. If you don't want this to happen, you can have have your job disable or delete itself after completion. For example:

```ruby
  def handle_response(r, session, job, request, data)
    QBWC.delete_job(job)
  end

```

Alternately, you can custom logic in your worker's `requests` and `should_run?` methods, as described below.


## Workers ##

A job is associated to a worker, which is an object descending from `QBWC::Worker` that can define three methods:

- `requests(job, session, data)` - defines the request(s) that QuickBooks should process - returns a `Hash` or an `Array` of `Hash`es.
- `should_run?(job, session, data)` - whether this job should run (e.g. you can have a job run only under certain circumstances) - returns `Boolean` and defaults to `true`.
- `handle_response(response, session, job, request, data)` - defines what to do with the response from Quickbooks.

All three methods are not invoked until a QuickBooks Web Connector session has been established with your web service.

A sample worker to get a list of customers from QuickBooks:

```ruby
require 'qbwc'

class CustomerTestWorker < QBWC::Worker

  def requests(job, session, data)
    {
      :customer_query_rq => {
        :xml_attributes => { "requestID" =>"1", 'iterator'  => "Start" },
        :max_returned => 100
      }
    }
  end

  def handle_response(r, session, job, request, data)
    # handle_response will get customers in groups of 100. When this is 0, we're done.
    complete = r['xml_attributes']['iteratorRemainingCount'] == '0'

    r['customer_ret'].each do |qb_cus|
      qb_id = qb_cus['list_id']
      qb_name = qb_cus['name']
      Rails.logger.info("#{qb_id} #{qb_name}")
    end
  end

end
```


Use the [Onscreen Reference for Intuit Software Development Kits](https://developer-static.intuit.com/qbSDK-current/Common/newOSR/index.html) (use Format: qbXML) to see request and response formats to use in your jobs. Use underscored, lowercased versions of all tags (e.g. `customer_query_rq`, not `CustomerQueryRq`).  Note that while requests include the top-level tag (e.g. `customer_query_rq`), the response hash passed to `QBWC::Worker#handle_response` does not include a corresponding top-level tag such as `customer_query_rs` (despite it being in the actual QBXML and shown in the OSR).

### Defining requests outside of a worker ###

You can pass requests (via a `Hash`, `String`, or array of `Hash`es and `String`s) to `QBWC.add_job` rather than having `QBWC::Worker#requests` define them.

```ruby
require 'qbwc'
requests = {
  :customer_query_rq => {
    :xml_attributes => { "requestID" =>"1", 'iterator'  => "Start" },
    :max_returned => 100
  }
}
# QBWC will run the contents of the requests variable, and will not use CustomerTestWorker#requests.
QBWC.add_job(:list_customers, true, '', CustomerTestWorker, requests)
```

### Passing data to a worker ###

`QBWC::Worker#handle_response` method cannot access variables that are in-memory at the time that `QBWC.add_job` is called; however, you can optionally pass a serializable value (for example, `String`, `Array`, or `Hash`) to `QBWC.add_job`. This data will be passed to `QBWC::Worker#handle_response` during a QuickBooks Web Connector session.

```ruby
require 'qbwc'
extra_data = "something important"
QBWC.add_job(:list_customers, true, '', CustomerTestWorker, nil, extra_data)

class CustomerTestWorker < QBWC::Worker

  # ...

  def handle_response(r, session, job, request, data)
    # data here is "something important"
  end

end
```

## Sessions ##

In certain cases, you may want to perform some initialization prior to each QuickBooks Web Connector session. For this purpose, you may optionally provide initialization code that will be invoked once when each QuickBooks Web Connector session is established, and prior to executing any queued jobs. This initialization code will not be invoked for any session in which no jobs are queued.

You assign this initialization code either (a) during configuration, and/or (b) in application code by calling `set_session_initializer` (prior to any QuickBooks Web Connector session being established). For example:

In config/initializers/qbwc.rb:

```ruby
c.session_initializer = Proc.new{|session|
  puts "New QuickBooks Web Connector session has been established (configured session initializer)"
}
```

In application code:
```ruby
  require 'qbwc'

  QBWC.set_session_initializer() do |session|
    puts "New QuickBooks Web Connector session has been established (overridden session initializer)"
    @information_from_jobs = {}
  end if the_application_needs_a_different_session_initializer

  QBWC.add_job(:list_customers, false, '', CustomerTestWorker)

```

Note: If you `set_session_initializer` in your application code, you're only affecting the process that your application code runs in. A request to another process (e.g. if you're multiprocess or you restarted the server) means that QBWC won't see the session initializer.

Note: a QuickBooks Web Connector session is established when you manually run (update) an application's web service in QuickBooks Web Connector, or when QuickBooks Web Connector automatically executes a scheduled update.

Similarly, it is possible to set a block to be run upon successful completion of a session.

```ruby
  QBWC.session_complete_success = lambda do |session|
    total_time = Time.now - session.began_at
    puts "Total run time of this session was #{total_time}s"
  end
```

Note that if `QBWC.on_error == :stop` and an error is encountered, this block will not be run.

## Handling errors ##

By default, when an error response is received from QuickBooks, `QBWC::Worker#handle_response` will be invoked but no further requests will be processed in the current job or in subsequent jobs. However, the job will remain persisted and so will be attempted again at next QuickBooks Web Connector session. Unless there is some intervention, presumably the job will fail again and block all remaining jobs and their requests from being serviced.

To have qbwc continue with the next request after receiving an error, set `on_error` to `:continue` in `config/initializers/qbwc.rb`.

## Contributing to qbwc

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Run tests - `rake test`.
