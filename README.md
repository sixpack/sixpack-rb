# Sixpack

Ruby client library for SeatGeek's Sixpack ab testing framework.

## Installation

Add this line to your application's Gemfile:

    gem 'sixpack-client'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sixpack-client

## Usage

Basic example:

```ruby
require 'sixpack'

session = Sixpack::Session.new

# Participate in a test (creates the test if necessary)
session.participate("new-test", ["alternative-1", "alternative-2"])

# Convert
session.convert("new-test")
```

Each session has a `client_id` associated with it that must be preserved across requests. Here's what the first request might look like:

```ruby
session = Sixpack::Session.new
session.participate("new-test", ["alternative-1", "alternative-2"])
set_cookie_in_your_web_framework("sixpack-id", session.client_id)
```

For future requests, create the `Session` using the `client_id` stored in the cookie:

```ruby
client_id = get_cookie_from_web_framework("sixpack-id")
session = Sixpack::Session.new client_id
session.convert("new-test")
```

Sessions can take an optional `options` dictionary that takes `host` and `timeout` as keys. This allows you to customize Sixpack's location.

    options = {'host': 'http://mysixpacklocation.com'}
    session = Session(client_id="123", options=options)

If Sixpack is unreachable or other errors occur, sixpack-rb will provide the control alternative.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Write and run some tests with `$ rake`
4. Commit your changes (`git commit -am 'Added some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request
