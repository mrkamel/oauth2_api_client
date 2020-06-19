require File.expand_path("./spec_helper", __dir__)

class HttpTestRequest
  attr_accessor :calls

  def initialize
    self.calls = []
  end

  [:timeout, :headers, :cookies, :via, :encoding, :accept, :auth, :basic_auth].each do |method|
    define_method method do |*args|
      dup.tap do |request|
        request.calls = calls + [[method, args]]
      end
    end
  end
end

RSpec.describe Oauth2ApiClient do
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
      client = described_class.new(
        base_url: "http://localhost/",
        client_id: "client_id",
        client_secret: "client_secret",
        oauth_token_url: "http://localhost/oauth2/token"
      )

      expect(client.token).to eq("access_token")
    end

    it "returns the cached token if existing" do
      cache = ActiveSupport::Cache::MemoryStore.new

      allow(cache).to receive(:fetch).and_return("cached_token")

      client = described_class.new(
        base_url: "http://localhost/",
        client_id: "client_id",
        client_secret: "client_secret",
        oauth_token_url: "http://localhost/oauth2/token",
        cache: cache
      )

      expect(client.token).to eq("cached_token")
    end

    it "caches the token" do
      cache = ActiveSupport::Cache::MemoryStore.new

      allow(cache).to receive(:fetch).and_yield

      client = described_class.new(
        base_url: "http://localhost/",
        client_id: "client_id",
        client_secret: "client_secret",
        oauth_token_url: "http://localhost/oauth2/token",
        max_token_ttl: 60,
        cache: cache
      )

      client.token

      expect(cache).to have_received(:fetch).with("oauth_api_client|http://localhost/|http://localhost/oauth2/token|client_id", expires_in: 60)
    end
  end

  [:timeout, :headers, :cookies, :via, :encoding, :accept, :auth, :basic_auth].each do |method|
    describe "##{method}" do
      it "creates a dupped instance" do
        client = described_class.new(
          base_url: "http://localhost/",
          client_id: "client_id",
          client_secret: "client_secret",
          oauth_token_url: "http://localhost/oauth2/token",
          base_request: HttpTestRequest.new
        )

        client1 = client.send(method, "key1")
        client2 = client1.send(method, "key1")

        expect(client1.object_id).not_to eq(client2.object_id)
      end

      it "extends the request" do
        client = described_class.new(
          base_url: "http://localhost/",
          client_id: "client_id",
          client_secret: "client_secret",
          oauth_token_url: "http://localhost/oauth2/token",
          base_request: HttpTestRequest.new
        )

        client1 = client.send(method, "key1")
        client2 = client1.send(method, "key2")

        expect(client1.instance_variable_get(:@request).calls).to eq([[method, ["key1"]]])
        expect(client2.instance_variable_get(:@request).calls).to eq([[method, ["key1"]], [method, ["key2"]]])
      end
    end
  end

  describe "request" do
    it "prepends the base url" do
      stub_request(:get, "http://localhost/path?key=value")
        .to_return(status: 200, body: "ok")

      client = described_class.new(
        base_url: "http://localhost/",
        client_id: "client_id",
        client_secret: "client_secret",
        oauth_token_url: "http://localhost/oauth2/token"
      )

      expect(client.get("/path", params: { key: "value" }).to_s).to eq("ok")
    end

    it "passes the token in the authentication header" do
      stub_request(:get, "http://localhost/path")
        .with(headers: { "Authorization" => "Bearer access_token" })
        .to_return(status: 200, body: "ok", headers: {})

      client = described_class.new(
        base_url: "http://localhost/",
        client_id: "client_id",
        client_secret: "client_secret",
        oauth_token_url: "http://localhost/oauth2/token"
      )

      expect(client.get("/path").to_s).to eq("ok")
    end

    it "invalidates the cached token when an http unauthorized status is returned" do
      stub_request(:get, "http://localhost/path")
        .to_return(status: 401, body: "unauthorized")

      cache = ActiveSupport::Cache::MemoryStore.new

      client = described_class.new(
        base_url: "http://localhost/",
        client_id: "client_id",
        client_secret: "client_secret",
        oauth_token_url: "http://localhost/oauth2/token",
        cache: cache
      )

      expect { client.get("/path") }.to raise_error(described_class::HttpError)

      expect(cache.read("oauth_api_client|http://localhost/|http://localhost/oauth2/token|client_id")).to be_nil
    end

    it "retries the request when an http unauthorized status is returned" do
      stub_request(:get, "http://localhost/path")
        .to_return({ status: 401, body: "unauthorized" }, { status: 200, body: "ok" })

      client = described_class.new(
        base_url: "http://localhost/",
        client_id: "client_id",
        client_secret: "client_secret",
        oauth_token_url: "http://localhost/oauth2/token"
      )

      expect(client.get("/path").to_s).to eq("ok")
    end

    it "raises if the retried request also fails" do
      stub_request(:get, "http://localhost/path")
        .to_return(status: 401, body: "unauthorized")

      client = described_class.new(
        base_url: "http://localhost/",
        client_id: "client_id",
        client_secret: "client_secret",
        oauth_token_url: "http://localhost/oauth2/token"
      )

      expect { client.get("/path") }.to raise_error(described_class::HttpError)
    end
  end
end
