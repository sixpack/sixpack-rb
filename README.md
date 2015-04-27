# Sixpack

[![Build Status](https://travis-ci.org/seatgeek/sixpack-rb.svg?branch=master)](https://travis-ci.org/seatgeek/sixpack-rb)

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
resp = session.participate("new-test", ["alternative-1", "alternative-2"])
if resp["alternative"]["name"] == "alternative-1"
    css_style = "blue"
end

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
session = Sixpack::Session.new(client_id)
session.convert("new-test")
```

Sessions can take an optional `options` hash that takes `:base_url`, and a params hash that takes `:ip_address`, and `:user_agent` a keys. If you would like to instantiate a session with a known client id, you can do that here. IP address and user agent can be passed to assist in bot detection.

    options = {
        :base_url => 'http://mysixpacklocation.com'
    }
    params = {
        :ip_address => '1.2.3.4'
    }
    session = Session(client_id="123", options=options, params=params)

If Sixpack is unreachable or other errors occur, sixpack-rb will provide the control alternative object.

## Configuration

You can configure the Sixpack in the configure block:

```ruby
Sixpack.configure do |config|
  config.base_url = 'http://10.20.30.40:5000'
end
```

You can use the `configure` block when initializing your app, for instance in a
Rails initializer.

Note that options, passed directly into `Session` constructor override the configuration options.

```ruby
Sixpack.configure do |config|
  config.base_url = 'http://foo:5000'
end

s = Sixpack::Session.new(id, base_url: 'http://bar:6000')

expect(s.base_url).to eq 'http://bar:6000' #=> true

### Configuration options

* base_url - to set the base_url for the sixpack API server
* user - set http basic authentication user
* password - set http basic authentication password
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Write and run some tests with `$ rake`
4. Commit your changes (`git commit -am 'Added some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request
