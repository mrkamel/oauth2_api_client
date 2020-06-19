class Oauth2ApiClient
  # The TokenProvider class is responsible for obtaining and caching an oauth2
  # token, when client id, client secret and token url is given.
  #
  # @example
  #   Oauth2ApiClient::TokenProvider.new(
  #     client_id: "client id",
  #     client_secret: "client secret",
  #     token_url: "https://auth.example.com/oauth2/token",
  #     cache: Rails.cache, # optional
  #     max_token_ttl: 1800 # optional
  #   )

  class TokenProvider
    # Creates a new TokenProvider instance.
    #
    # @param client_id [String] The client id
    # @param client_secret [String] The client secret
    # @param token_url [String] The oauth2 endpoint for generating tokens
    # @param cache An ActiveSupport compatible cache implementation. Defaults
    #   to `ActiveSupport::Cache::MemoryStore.new`
    # @param max_token_ttl [#to_i] A maximum token lifetime. Defaults to 3600
    #
    # @example
    #   Oauth2ApiClient::TokenProvider.new(
    #     client_id: "client id",
    #     client_secret: "client secret",
    #     token_url: "https://auth.example.com/oauth2/token",
    #   )

    def initialize(client_id:, client_secret:, token_url:, cache: ActiveSupport::Cache::MemoryStore.new, max_token_ttl: 3600)
      @client_id = client_id
      @client_secret = client_secret
      @token_url = token_url
      @max_token_ttl = max_token_ttl
      @cache = cache

      oauth_uri = URI.parse(token_url)

      @oauth_client = OAuth2::Client.new(
        @client_id,
        @client_secret,
        site: URI.parse("#{oauth_uri.scheme}://#{oauth_uri.host}:#{oauth_uri.port}/").to_s,
        token_url: oauth_uri.path
      )
    end

    # Returns the oauth2 token, either from the cache, or newly generated
    #
    # @return [String] the token

    def token
      @cache.fetch(cache_key, expires_in: @max_token_ttl.to_i) do
        @oauth_client.client_credentials.get_token.token
      end
    end

    # Invalidates the cached token, i.e. removes it from the cache
    #
    # @return [String] the token

    def invalidate_token
      @cache.delete(cache_key)
    end

    private

    def cache_key
      @cache_key ||= ["oauth_api_client", @token_url, @client_id].join("|")
    end
  end
end
