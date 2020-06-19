require "ruby2_keywords"
require "oauth2"
require "http"
require "ruby2_keywords"
require "active_support"

require "oauth2_api_client/version"
require "oauth2_api_client/http_error"

# The Oauth2ApiClient class is a client wrapped around the oauth2 and http-rb
# gem to interact with APIs using oauth2 for authentication with automatic
# token caching and renewal.

class Oauth2ApiClient
  # Creates a new Oauth2ApiClient
  #
  # @param base_url [String] The base url of the API to interact with
  # @param client_id [String] The client id to use for oauth2 authentication
  # @param client_secret [String] The client secret to use for oauth2 authentication
  # @param oauth_token_url [String] The url to obtain tokens from
  # @param cache The cache instance to cache the tokens, e.g. `Rails.cache`.
  #   Defaults to `ActiveSupport::Cache::MemoryStore.new`
  # @param max_token_ttl [#to_i] The max lifetime of the token in the cache
  # @param base_request You can pass some http-rb rqeuest as the base. Useful,
  #   if some information needs to be passed with every request. Defaults to
  #   `HTTP`
  #
  # @example
  #   Oauth2ApiClient.new(
  #     base_url: "https://api.example.com/",
  #     client_id: "the client id",
  #     client_secret: "the client secret",
  #     oauth_token_url: "https://auth.example.com/oauth2/token",
  #     cache: Rails.cache,
  #     base_request: HTTP.headers("User-Agent" => "API client")
  #   )

  def initialize(base_url:, client_id:, client_secret:, oauth_token_url:, cache: ActiveSupport::Cache::MemoryStore.new, max_token_ttl: 3600, base_request: HTTP)
    @base_url = base_url
    @client_id = client_id
    @client_secret = client_secret
    @oauth_token_url = oauth_token_url
    @max_token_ttl = max_token_ttl
    @cache = cache
    @request = base_request

    oauth_uri = URI.parse(oauth_token_url)

    @oauth_client = OAuth2::Client.new(
      @client_id,
      @client_secret,
      site: URI.parse("#{oauth_uri.scheme}://#{oauth_uri.host}:#{oauth_uri.port}/").to_s,
      token_url: oauth_uri.path
    )
  end

  # Returns a oauth2 token to use for authentication

  def token
    @cache.fetch(cache_key, expires_in: @max_token_ttl.to_i) do
      @oauth_client.client_credentials.get_token.token
    end
  end

  [:timeout, :headers, :cookies, :via, :encoding, :accept, :auth, :basic_auth].each do |method|
    define_method method do |*args|
      dup.tap do |client|
        client.instance_variable_set(:@request, @request.send(method, *args))
      end
    end

    ruby2_keywords method
  end

  [:get, :post, :put, :delete, :head, :options].each do |method|
    define_method method do |path, options = {}|
      execute(method, path, options)
    end
  end

  private

  def cache_key
    @cache_key ||= ["oauth_api_client", @base_url, @oauth_token_url, @client_id].join("|")
  end

  def execute(verb, path, options = {})
    with_retry do
      response = @request.auth("Bearer #{token}").send(verb, URI.join(@base_url, path), options)

      return response if response.status.success?

      raise HttpError.new(response.status.to_s, response)
    end
  end

  def with_retry
    retried = false

    begin
      yield
    rescue HttpError => e
      @cache.delete(cache_key) if e.response.status.unauthorized?

      raise(e) if retried || !e.response.status.unauthorized?

      retried = true

      retry
    end
  end
end
