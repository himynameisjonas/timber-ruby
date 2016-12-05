# Timber

<p align="center" style="background: #140f2a;">
<a href="http://github.com/timberio/timber-ruby"><img src="http://files.timber.io/images/ruby-library-readme-header.gif" /></a>
</p>

[![CircleCI](https://circleci.com/gh/timberio/timber-ruby.svg?style=shield&circle-token=:circle-token)](https://circleci.com/gh/timberio/timber-ruby/tree/master)
[![Coverage Status](https://coveralls.io/repos/github/timberio/timber-ruby/badge.svg?branch=master)](https://coveralls.io/github/timberio/timber-ruby?branch=master)
[![Code Climate](https://codeclimate.com/github/timberio/timber-ruby/badges/gpa.svg)](https://codeclimate.com/github/timberio/timber-ruby)
[![View docs](https://img.shields.io/badge/docs-viewdocs-blue.svg?style=flat-square "Viewdocs")](http://www.rubydoc.info/github/timberio/timber-ruby)


1. [What is timber?](#what-is-timber)
2. [Examples](#examples)
3. [Pricing](#pricing)
2. [Install](#install)


## What is Timber?

Glad you asked. Timber *automatically* augments your logs with structured data without any
risk of code debt or lock-in. For example, it turns this:

```
Completed 200 OK in 117ms (Views: 85.2ms | ActiveRecord: 25.3ms)
```

Into this:

```json
{
  "dt": "2016-12-01T02:23:12.236543Z",
  "level": "info",
  "message": "Completed 200 OK in 117ms (Views: 85.2ms | ActiveRecord: 25.3ms)",
  "context": {
    "http": {
      "method": "GET",
      "path": "/checkout",
      "remote_addr": "123.456.789.10",
      "request_id": "abcd1234"
    },
    "user": {
      "id": 2,
      "name": "Ben Johnson",
      "email": "ben@johnson.com"
    }
  },
  "event": {
    "http_response": {
      "status": 200,
      "time_ms": 117,
      "rails": {
        "view_time_ms": 85.2,
        "active_record_time_ms": 25.3
      }
    }
  }
}
```

Allowing you to run queries that [even your mother would get excited about](http://i.giphy.com/7JYWGKgwxga5i.gif):

  1. `context.user.email:ben@johnson.com` - Tail a specific user!
  2. `context.http.request_id:1234` - View *all* logs for a given HTTP request!
  3. `event.http_reponse.time_ms>3000` - Easily find outliers and have the proper context to fix them!
  4. `level:warn` - Log levels in your logs. Imagine that!

For a full list of events, see `Timber::Events`.

## Examples

> Another service? More lock-in? More code debt? More sadness? :*(

Nope! This is exactly why we created Timber. Timber is Just Logging™. No special API, no risk
of code debt, no weird proprietary data format locked away in our servers. Absolutely no lock-in!

Besides automatically capturing known events, you can also add your custom events. Check it out:

```ruby
# Simple (original Logger interface remains untouched)
Logger.warn "Payment rejected for customer abcd1234, reason: Card expired"

# More advanced
Logger.warn message: "Payment rejected", type: :payment_rejected, data: %{customer_id: "abcd1234", amount: 100, reason: "Card expired"}

# Using a Struct
PaymentRejectedEvent = Struct.new(:customer_id, :amount, :reason) do
  def message
    "Payment rejected for #{customer_id}"
  end

  def type
    :payment_rejected
  end
end
Logger.warn PaymentRejectedEvent.new("abcd1234", 100, "Card expired")
```

No Timber specific code anywhere! In fact, this approach pushes things the opposite way. What if,
as a result of structured logging, you could start decoupling other services?

Before:

```
               |---[HTTP]---> sentry / bugsnag / etc
My Application |---[HTTP]---> librato / graphite / etc
               |---[HTTP]---> new relic / etc
               |--[STDOUT]--> logs
                                |---> Logging service
                                |---> S3
                                |---> RedShift
```


After:

```
                                                    |-- sentry / bugsnag / etc
                                                    |-- librato / graphite / etc
My Application |--[STDOUT]--> logs ---> Timber ---> |-- new relic / etc
                               ^                    |-- S3
                               |                    |-- RedShift
                               |                                 ^
                    fast, efficient, durable,                    |
                      replayable, auditable         change any of these without
                                                        touching your code
                                                       *and* backfill them!
```


## Pricing

> This is all gravy, but wouldn't it get expensive?

If you opt to send your data to the [Timber service](https://timber.io), we only charge for
the size of the `message` and `dt` attributes. The additional `event` and `context` data are
stored at no cost to you. [Say wha?!](http://i.giphy.com/l0HlL2vlfpWI0meJi.gif). This ensures
pricing remains predictable. And our pricing is simple, we charge per GB transferred to us and
retained, no user limits, and no weird feature matrixes. Lastly, the data is yours, in a simple
non-proprietary JSON format.

For more details checkout our [timber.io](https://timber.io).

## Install

Install the gem:

```ruby
# Gemfile
gem 'timberio', require: "timber"
```

For Heroku:

```ruby
# config/environments/production.rb (or staging, etc)
config.logger = Timber::Logger.new(STDOUT)
```

For non-Heroku:

```ruby
# config/environments/production.rb (or staging, etc)
log_device = Timber::LogDevices::HTTP.new(ENV['TIMBER_KEY']) # key can be obtained by signing up at https://timber.io
config.logger = Timber::Logger.new(log_device)
```

That's it! Log to your heart's content.

For documentation on logging structured events, and other features,
checkout [the docs](http://thedocs.com/).
