# oauth2_api_client

[![Build](https://github.com/mrkamel/oauth2_api_client/workflows/test/badge.svg)](https://github.com/mrkamel/oauth2_api_client/actions?query=workflow%3Atest+branch%3Amaster)
[![Gem Version](https://badge.fury.io/rb/oauth2_api_client.svg)](http://badge.fury.io/rb/oauth2_api_client)

Oauth2ApiClient is a small, but powerful client around
[oauth2](https://github.com/oauth-xx/oauth2) and
[http-rb](https://github.com/httprb/http) to interact with APIs which use
oauth2 for authentication.

```ruby
client = Oauth2ApiClient.new(base_url: "https://api.example.com", token "oauth2 token")

client.post("/orders", json: { address: "..." }).status.success?
client.headers("User-Agent" => "API Client").timeout(read: 5, write: 5).get("/orders").parse(:json)
# ...
```

In case an API is unprotected and you still want to use Oauth2ApiClient, you
can simply not pass any token:

```ruby
client = Oauth2ApiClient.new(base_url: "...")
```

Oauth2ApiClient is capable of generating oauth2 tokens, when a client id,
client secret and oauth token url is given with automatic token caching and
renewal on expiry, including retry of the current request.

```ruby
client = Oauth2ApiClient.new(
  base_url: "https://api.example.com",
  token: Oauth2ApiClient::TokenProvider.new(
    client_id: "client id",
    client_secret: "client secret",
    token_url: "https.//auth.example.com/oauth2/token",
    cache: Rails.cache, # optional,
    max_token_ttl: 1800 # optional
  )
)
```

Please note, `get`, `post`, `put`, etc. will raise
`Oauth2ApiClient::ResponseError` unless the response code is 2xx. More
specifically, it will e.g. raise `Oauth2ApiClient::ResponseError::NotFound` for
a 404 status code, `Oauth2ApiClient::ResponseError::InternalServerError` for a
500 status code, etc.

## Default query params

In addition to the DSL of http-rb Oauth2ApiClient allows to set default query
params, which can be useful for some APIs:

```ruby
client = Oauth2ApiClient.new(base_url: "https://api.example.com").params(key1: "value1")
client.get("/path", params: { key2: "value" })
#=> GET https://api.example.com/path?key1=value1&key2=value2
```

## Persistent connections (keep-alive)

You can use keep-alive on the base url via:

```ruby
client = Oauth2ApiClient.new(base_url: "https://api.example.com/v1").persistent(timeout: 5)
client.get("/path")
```

where the `timeout` is optional. Please note that you must consume the response
via `#to_s`, `#parse` or `#flush` before sending next request via persistent
connection. Check out the
[http-rb docs](https://github.com/httprb/http/wiki/Persistent-Connections-%28keep-alive%29)
for more info.

## Install

Add this line to your application's Gemfile:

```ruby
gem 'oauth2_api_client'
```

and then execute

```
$ bundle
```

or install it via

```
$ gem install oauth2_api_client
```

## Reference Docs

The reference docs can be found at
[http://www.rubydoc.info/github/mrkamel/oauth2_api_client](http://www.rubydoc.info/github/mrkamel/oauth2_api_client)

## Semantic Versioning

Oauth2ApiClient is using Semantic Versioning: [SemVer](http://semver.org/)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
