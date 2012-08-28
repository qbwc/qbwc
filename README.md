# Quickbooks Web Connector (QBWC)

Be Warned, this code is still hot out of the oven. 

## Installation

Install the gem

  `gem install qbwc`

Add it to your Gemfile

  `gem "qbwc"`

Run the generator:

  `rails generate qbwc:install`

## Features

Qbwc was designed to add quickbooks web connector integration to your Rails 3 application. 

* Implementation of the Soap WDSL spec for Intuit Quickbooks and Point of Sale
* Integration with the [quickbooks_api](https://github.com/skryl/quickbooks_api) gem providing qbxml processing

## Getting Started

### Configuration

All configuration takes place in the gem initializer. See the initializer for more details regarding the configuration options.

### Basics

The Qbwc gem provides a persistent work queue for the Web Connector to talk to.

Every time the Web Connector initiates a new conversation with the application a
Session will be created. The Session is a collection of jobs and the requests
that comprise these jobs. A new Session will automatically queue up all the work
available across all currently enabled jobs for processing by the web connector.
The session instance will persist across all requests until the work it contains
has been exhausted. You never have to interact with the Session class directly
(unless you want to...) since creating a new job will automatically add it's
work to the next session instance.

A Job is just a named work queue. It consists of a name and a code block. The
block can contain:

  * A single qbxml request
  * An array of qbxml requests
  * Code that genrates a qbxml request
  * Code that generates an array of qbxml requests

*Note: All requests should be in ruby hash form, generated using quickbooks_api. Raw
requests will be supported soon.*

The code block is re-evaluated every time a session instance with that job is
created. Only enabled jobs are added to a new session instance. 

An optional response processor block can also be added to a job. Responses to
all requests are either processed immediately after being received or saved for
processing after the web connector closes its connection. The delayed processing
configuration option decides this.

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

### Adding Jobs

Create a new job

    Qbwc.add_job('my job') do
      # work to do
    end

Add a response proc

    Qbwc.jobs['my job'].set_response_proc do |r|
      # response processing work here
    end

Caveats
  * Jobs are enabled by default
  * Using a non unique job name will overwrite the existing job


### Managing Jobs

Jobs can be added, removed, enabled, and disabled. See the above section for
details on adding new jobs. 

Removing jobs is as easy as deleting them from the jobs hash.                   

    Qbwc.jobs.delete('my job')

Disabling a job

    Qbwc.jobs['my job'].disable

Enabling a job

    Qbwc.jobs['my job'].enable


## Contributing to qbwc
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.
