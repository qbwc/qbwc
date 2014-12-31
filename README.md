QBWC lets your Rails 4 application talk to QuickBooks Desktop.

## Installation

`gem install qbwc`

Or add it to your Gemfile

`gem "qbwc"`

and run

`bundle install`

## Configuration

Run the generator:

`rails generate qbwc:install`

Then the migrations:

`rake db:migrate`

Open config/initializers/qbwc.rb and check the settings there. The defaults are reasonable, but make a new GUID for owner_id.

(Re-)start your app.

Quickbooks *requires* HTTPS connections when connecting to remote machines. [ngrok](https://ngrok.com/) may be useful to fulfill this requirement.

## QuickBooks Configuration

Install [QuickBooks Web Connector](http://marketplace.intuit.com/webconnector/) on the machine that has QuickBooks installed.

On the QuickBooks machine, visit the path /qbwc/qwc on your domain over an HTTPS connection. Download the file it provides. In QuickBooks Web Connector, click "Add an application", and pick the file. Give Quickbooks the password you specified in config/initializers/qbwc.rb.

At this point, QuickBooks Web Connector should be able to send requests to your app, but will have nothing to do, and say "No data exchange required".

## Creating Jobs

QuickBooks Web Connector (the app you installed above) acts as the HTTP client, and your app acts as the HTTP server. To have QuickBooks perform tasks, you must add a qbwc job to your app, then get QuickBooks Web Connector to check your app for work to do.

A job is associated to a worker, which is an object descending from `QBWC::Worker` that can define three methods:

- `requests` - defines the request(s) that QuickBooks should process - returns a `Hash` or an `Array` of `Hash`es.
- `should_run?` - whether this job should run (e.g. you can have a job run only under certain circumstances) - returns `Boolean` and defaults to `true`.
- `handle_response(response, job)` - defines what to do with the response from Quickbooks.

All three methods are not invoked until a QuickBooks Web Connector session has been established with your web service.

A sample worker to get a list of customers from QuickBooks:

```ruby
require 'qbwc'

class CustomerTestWorker < QBWC::Worker

	def requests
		{
			:customer_query_rq => {
				:xml_attributes => { "requestID" =>"1", 'iterator'  => "Start" },
				:max_returned => 100
			}
		}
	end

	def handle_response(r, job)
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

And to create the job (e.g. from `rails console` or wherever):

```ruby
require 'qbwc'
QBWC.add_job(:list_customers, false, '', CustomerTestWorker)
```

After adding a job, it will remain active and will run every time QuickBooks Web Connector runs an update. If you don't want this to happen, you can have custom logic in your worker's `should_run?` or have your job disable or delete itself after completion. For example:

```ruby
	def handle_response(r, job)
		QBWC.delete_job(job.name)
	end

```


Use the [Onscreen Reference for Intuit Software Development Kits](https://developer-static.intuit.com/qbSDK-current/Common/newOSR/index.html) (use Format: qbXML) to see request and response formats to use in your jobs. Use underscored, lowercased versions of all tags (e.g. `customer_query_rq`, not `CustomerQueryRq`).

### Referencing memory values when constructing requests ###

A QBWC::Worker#requests method cannot access values that are in-memory (local variables, model attributes, etc.) at the time that QBWC.add_job is called; however, in lieu of using QBWC::Worker#requests, you can optionally construct and pass requests directly to QBWC.add_job (scalar request or array of requests). These requests will be immediately persisted by QBWC.add_job (in contrast to requests constructed by QBWC::Worker#requests, which are persisted during a QuickBooks Web Connector session).

If requests are passed to QBWC.add_job, any QBWC::Worker#requests method will be ignored and will not be invoked during QuickBooks Web Connector sessions.

### Check versions ###

If you want to return server version or check client version you can override server_version_response or check_client_version methods in your controller. Check QB web connector guide for allowed responses.

## Contributing to qbwc

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.
