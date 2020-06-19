require File.expand_path("../spec_helper", __dir__)

RSpec.describe Oauth2ApiClient::TokenProvider do
  before do
    token_response = {
      access_token: "access_token",
      token_type: "bearer",
      expires_in: 3600,
      refresh_token: "refresh_token",
      scope: "create"
    }

    stub_request(:post, "http://localhost/oauth2/token")
      .to_return(status: 200, body: JSON.generate(token_response), headers: { "Content-Type" => "application/json" })
  end

  describe "#token" do
    it "returns a oauth2 token" do
      token_provider = described_class.new(
        client_id: "client_id",
        client_secret: "client_secret",
        token_url: "http://localhost/oauth2/token"
      )

      expect(token_provider.token).to eq("access_token")
    end

    it "returns the cached token if existing" do
      cache = ActiveSupport::Cache::MemoryStore.new

      allow(cache).to receive(:fetch).and_return("cached_token")

      token_provider = described_class.new(
        client_id: "client_id",
        client_secret: "client_secret",
        token_url: "http://localhost/oauth2/token",
        cache: cache
      )

      expect(token_provider.token).to eq("cached_token")
    end

    it "caches the token" do
      cache = ActiveSupport::Cache::MemoryStore.new

      allow(cache).to receive(:fetch).and_yield

      token_provider = described_class.new(
        client_id: "client_id",
        client_secret: "client_secret",
        token_url: "http://localhost/oauth2/token",
        max_token_ttl: 60,
        cache: cache
      )

      token_provider.token

      expect(cache).to have_received(:fetch).with("oauth_api_client|http://localhost/oauth2/token|client_id", expires_in: 60)
    end
  end

  describe "#invalidate_token" do
    it "deletes the token from the cache" do
      cache = ActiveSupport::Cache::MemoryStore.new

      token_provider = described_class.new(
        client_id: "client_id",
        client_secret: "client_secret",
        token_url: "http://localhost/oauth2/token",
        cache: cache
      )

      token_provider.token

      expect(cache.read("oauth_api_client|http://localhost/oauth2/token|client_id")).not_to be_nil

      token_provider.invalidate_token

      expect(cache.read("oauth_api_client|http://localhost/oauth2/token|client_id")).to be_nil
    end
  end
end
