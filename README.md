QBWC lets your Rails 4 application talk to QuickBooks.

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

**qbwc currently has a limitation where the process where you add the job must be the same process that QuickBooks Web Connector ends up talking to, or the job won't work. This means having a multi-process server, or even restarting your app, will mean your jobs won't work. This sucks and will hopefully be fixed soon. Because of this limitation, you will need to add the job from your server process (e.g. in a controller) for job to work.**

A sample job to get a list of customers from QuickBooks:

```ruby
j = QBWC.add_job(:list_customers, '', {
	:customer_query_rq => {
		:xml_attributes => { "requestID" => "1", 'iterator' => "Start" },
		# This will limit results to 100 per response, so our response proc will get called 
		# multiple times.
		:max_returned => 100
	}
})
j.set_response_proc do |r|
  # Iterate through the customers in this response
	r['customer_ret'].each do |qb_cus|
		qb_id = qb_cus['list_id']
		qb_name = qb_cus['name']
		Rails.logger.info "#{qb_id} - #{qb_name}"
	end
	# When r['xml_attributes']['iteratorRemainingCount'] == '0' then we've received all customers.
end
```

After adding a job, it will remain active and will run again every time QuickBooks Web Connector runs an update.

Use the [Onscreen Reference for Intuit Software Development Kits](https://developer-static.intuit.com/qbSDK-current/Common/newOSR/index.html) (use Format: qbXML) to see request and response formats to use in your jobs. Use underscored, lowercased versions of all tags (e.g. `customer_query_rq`, not `CustomerQueryRq`).

## The Details

The QBWC gem provides a persistent work queue for the Web Connector to talk to.

Every time the Web Connector initiates a new conversation with the application a
Session will be created. The Session is a collection of jobs and the requests
that comprise these jobs. A new Session will automatically queue up all the work
available across all currently enabled jobs for processing by the web connector.
The session instance will persist across all requests until the work it contains
has been exhausted. You never have to interact with the Session class directly
(unless you want to...) since creating a new job will automatically add it's
work to the next session instance.

A Job is just a named work queue. It consists of a name, a company (defaults to QBWC.company_file_path), and some qbxml requests. If requests are not provided, a code block that generates next qbxml request can be provided.

*Note: All requests may be in ruby hash form, generated qbxml
Raw requests are supported supported as of 0.0.3 (8/28/2012)*

The code block is called every time a session must send a request. If block return nil, no request will be send and next pending job will be checked.

Only enabled jobs with pending requests are added to a new session instance. Pending requests is checked calling code block, but an optional pending requests checking block can also be added to a job, so request creation can be avoided.

An optional response processor block can also be added to a job. Responses to
all requests are processed immediately after being received.

Here is the rough order in which things happen:

1. The Web Connector initiates a connection
2. A new Session is created (with work from all enabled jobs with pending requests)
3. The web connector requests work
4. The session responds with the next request in the work queue
5. The web connector provides a response
6. The session responds with the current progress of the work queue (0 - 100)
6. The response is processed
7. If progress == 100 then the web connector closes the connection, otherwise goto 3

### Adding Jobs

Create a new job

```
QBWC.add_job('my job') do
# work to do
end
```

Add a checking proc

```
QBWC.jobs['my job'].set_checking_proc do
# pending requests checking here
end
```

Add a response proc

```
QBWC.jobs['my job'].set_response_proc do |r|
# response processing work here
end
```

Caveats
* Jobs are enabled by default
* Using a non unique job name will overwrite the existing job

###Sample Jobs

```
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
```

Add a Customer (Unwrapped)

```
{
:customer_add_rq    => 
[
{
:xml_attributes => {"requestID" => "1"},  ##Optional
:customer_add   => { :name => "GermanGR" }
} 
] 
}
```

Get All Vendors (In Chunks of 5)

```
QBWC.add_job(:import_vendors, nil
{
:vendor_query_rq  =>
{
:xml_attributes => { "requestID" =>"1", 'iterator'  => "Start" },

:max_returned => 5,
:owner_id => 0,
:from_modified_date=> "1984-01-29T22:03:19"

}
}
)
```

Get All Vendors (Raw QBXML)

```
QBWC.add_job(:import_vendors, nil
'<?xml version="1.0"?>
<?qbxml version="7.0"?>
<QBXML>
<QBXMLMsgsRq onError="continueOnError">
<VendorQueryRq requestID="6" iterator="Start">
<MaxReturned>5</MaxReturned>
<FromModifiedDate>1984-01-29T22:03:19-05:00</FromModifiedDate>
<OwnerID>0</OwnerID>
</VendorQueryRq>
</QBXMLMsgsRq>
</QBXML>
'
)
```

### Managing Jobs

Jobs can be added, removed, enabled, and disabled. See the above section for
details on adding new jobs. 

Removing jobs is as easy as deleting them from the jobs hash.                   

`QBWC.jobs.delete('my job')`

Disabling a job

`QBWC.jobs['my job'].disable`

Enabling a job

`QBWC.jobs['my job'].enable`

### Supporting multiple users/companies

Override get_user and current_company methods in the generated controller. authenticate_user must authenticate with username and password and return user if it's authenticated, nil in other case. current_company receives authenticated user and must return nil if there are no pending jobs or company where jobs will run. Currently this methods are like this:

```
protected
def authenticate_user(username, password)
username if username == QBWC.username && password == QBWC.password
end
def current_company(user)
QBWC.company_file_path if QBWC.pending_jobs(QBWC.company_file_path).presen
t?
end
```

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
