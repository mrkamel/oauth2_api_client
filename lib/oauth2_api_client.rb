require "ruby2_keywords"
require "oauth2"
require "http"
require "active_support"

require "oauth2_api_client/version"
require "oauth2_api_client/response_error"
require "oauth2_api_client/token_provider"

# The Oauth2ApiClient class is a client wrapped around the oauth2 and http-rb
# gem to interact with APIs using oauth2 for authentication with automatic
# token caching and renewal.

class Oauth2ApiClient
  # Creates a new Oauth2ApiClient
  #
  # @param base_url [String] The base url of the API to interact with
  # @param token [String, Oauth2ApiClient::TokenProvider] Allows to pass an
  #   existing token received via external sources or an instance of
  #   `Oauth2ApiClient::TokenProvider` which is capable of generating
  #   tokens when client id, client secret, etc. is given
  #
  # @example
  #   client = Oauth2ApiClient.new(
  #     base_url: "https://api.example.com",
  #     token: "the api token"
  #   )
  #
  #   client.post("/orders", json: { address: "..." }).status.success?
  #   client.headers("User-Agent" => "API Client").timeout(read: 5, write: 5).get("/orders").parse(:json)
  #
  # @example
  #   client = Oauth2ApiClient.new(
  #     base_url: "https://api.example.com",
  #     token: Oauth2ApiClient::TokenProvider.new(
  #       client_id: "the client id",
  #       client_secret: "the client secret",
  #       oauth_token_url: "https://auth.example.com/oauth2/token",
  #       cache: Rails.cache
  #     )
  #   )

  def initialize(base_url:, token: nil, base_request: HTTP)
    @base_url = base_url
    @token = token
    @request = base_request
  end

  # Returns a oauth2 token to use for authentication
  #
  # @return [String] The token

  def token
    return if @token.nil?

    @token.respond_to?(:to_str) ? @token.to_str : @token.token
  end

  def params(parms = {})
    dup.tap do |client|
      client.instance_variable_set(:@params, (@params || {}).merge(parms))
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

  def execute(verb, path, options = {})
    with_retry do
      request = @request
      request = request.headers({}) # Prevent thread-safety issue of http-rb: https://github.com/httprb/http/issues/558
      request = request.auth("Bearer #{token}") if token

      opts = options.dup
      opts[:params] = @params.merge(opts.fetch(:params, {})) if @params

      response = request.send(verb, "#{@base_url}#{path}", opts)

      return response if response.status.success?

      raise ResponseError.for(response)
    end
  end

  def with_retry
    retried = false

    begin
      yield
    rescue ResponseError => e
      if !retried && e.response.status.unauthorized? && @token.respond_to?(:invalidate_token)
        @token.invalidate_token

        retried = true

        retry
      end

      raise
    end
  end
end
