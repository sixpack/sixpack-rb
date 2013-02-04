# Sixpack

Ruby client library for SeatGeak's Sixpack ab testing framework.

## Installation

Add this line to your application's Gemfile:

    gem 'sixpack'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sixpack

## Usage

Basic example:

```
require 'sixpack'

session = Sixpack::Session.new

# Participate in a test (creates the test if necessary)
session.participate("new-test", ["alternative-1", "alternative-2"])

# Convert
session.convert("new-test")
```

Each session has a `client_id` associated with it that must be preserved across requests. Here's what the first request might look like:

```
session = Sixpack::Session.new
session.participate("new-test", ["alternative-1", "alternative-2"])
set_cookie_in_your_web_framework("sixpack-id", session.client_id)
```

For future requests, create the `Session` using the `client_id` stored in the cookie:

```
client_id = get_cookie_from_web_framework("sixpack-id")
session = Sixpack::Session.new client_id
session.convert("new-test")
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
