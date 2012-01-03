# Quickbooks Web Connector (QBWC)

Be Warned, this code is still hot out of the oven. 

## Installation

Install the gem:

  `gem install qbwc`

Add it to your Gemfile:

  `gem "qbwc"`

Run the generator:

  `rails generate qbwc:install`

## Getting Started

QBWC was designed to rapidly add quickbooks web support to your Rails 3 application.  All customization occurs in the initializer file for the gem.  

Things QBWC does for you. 

1. Spot on Implementation of the Soap WDSL spec for Intuit Quickbooks ( Point of Sale also supported)
2. Quick Start Generators to allow you to have functioning soap server in a single command. (rails generate qbwc:install)
3. Integration of the [quickbooks_api](https://github.com/skryl/quickbooks_api) gem providing requests pre processed hashes 
  
## Contributing to qbwc
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.
