require File.expand_path("./spec_helper", __dir__)

class HttpTestRequest
  attr_accessor :calls

  def initialize
    self.calls = []
  end

  [:persistent, :timeout, :headers, :cookies, :via, :encoding, :accept, :auth, :basic_auth].each do |method|
    define_method method do |*args|
      dup.tap do |request|
        request.calls = calls + [[method, args]]
      end
    end
  end
end

RSpec.describe Oauth2ApiClient do
  let!(:auth_request_stub) do
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
    it "returns the supplier token" do
      client = described_class.new(base_url: "http://localhost/", token: "access_token")

      expect(client.token).to eq("access_token")
    end

    it "returns a oauth2 token" do
      client = described_class.new(
        base_url: "http://localhost/",
        token: described_class::TokenProvider.new(
          client_id: "client_id",
          client_secret: "client_secret",
          token_url: "http://localhost/oauth2/token"
        )
      )

      expect(client.token).to eq("access_token")
    end
  end

  describe "#params" do
    it "creates a dupped instance" do
      client = described_class.new(base_url: "http://localhost")

      client1 = client.params(key1: "value1")
      client2 = client1.params(key2: "value2")

      expect(client1.object_id).not_to eq(client2.object_id)
    end

    it "merges the params" do
      client = described_class.new(base_url: "http://localhost")

      client1 = client.params(key1: "value1")
      client2 = client1.params(key2: "value2")

      expect(client2.instance_variable_get(:@params)).to eq(key1: "value1", key2: "value2")
    end

    it "merges the params with passed params in requests" do
      stub_request(:get, "http://localhost/api/path?key1=value1&key2=value2")
        .to_return(status: 200, body: "ok")

      client = described_class.new(base_url: "http://localhost/api", token: "token").params(key1: "value1")

      expect(client.get("/path", params: { key2: "value2" }).to_s).to eq("ok")
    end

    it "overwrites the default params when neccessary" do
      stub_request(:get, "http://localhost/api/path?key=value2")
        .to_return(status: 200, body: "ok")

      client = described_class.new(base_url: "http://localhost/api", token: "token").params(key: "value1")

      expect(client.get("/path", params: { key: "value2" }).to_s).to eq("ok")
    end

    it "passes the default params only when no params are given" do
      stub_request(:get, "http://localhost/api/path?key=value")
        .to_return(status: 200, body: "ok")

      client = described_class.new(base_url: "http://localhost/api", token: "token").params(key: "value")

      expect(client.get("/path").to_s).to eq("ok")
    end

    it "passes the params only when no default params are given" do
      stub_request(:get, "http://localhost/api/path?key=value")
        .to_return(status: 200, body: "ok")

      client = described_class.new(base_url: "http://localhost/api", token: "token")

      expect(client.get("/path", params: { key: "value" }).to_s).to eq("ok")
    end
  end

  [:timeout, :headers, :cookies, :via, :encoding, :accept, :auth, :basic_auth].each do |method|
    describe "##{method}" do
      it "creates a dupped instance" do
        client = described_class.new(base_url: "http://localhost/", token: "token", base_request: HttpTestRequest.new)

        client1 = client.send(method, "key1")
        client2 = client1.send(method, "key1")

        expect(client1.object_id).not_to eq(client2.object_id)
      end

      it "extends the request" do
        client = described_class.new(base_url: "http://localhost/", token: "token", base_request: HttpTestRequest.new)

        client1 = client.send(method, "key1")
        client2 = client1.send(method, "key2")

        expect(client1.instance_variable_get(:@request).calls).to eq([[method, ["key1"]]])
        expect(client2.instance_variable_get(:@request).calls).to eq([[method, ["key1"]], [method, ["key2"]]])
      end
    end
  end

  describe "#persistent" do
    it "delegates to the request and passes the correct base url without path" do
      client = described_class.new(base_url: "http://localhost/api", token: "token", base_request: HttpTestRequest.new)

      client1 = client.persistent("key1")
      client2 = client1.persistent("key2")

      expect(client1.instance_variable_get(:@request).calls).to eq([[:persistent, ["http://localhost", "key1"]]])
      expect(client2.instance_variable_get(:@request).calls).to eq([[:persistent, ["http://localhost", "key1"]], [:persistent, ["http://localhost", "key2"]]])
    end
  end

  describe "request" do
    it "prepends the base url" do
      stub_request(:get, "http://localhost/api/path?key=value")
        .to_return(status: 200, body: "ok")

      client = described_class.new(base_url: "http://localhost/api", token: "token")

      expect(client.get("/path", params: { key: "value" }).to_s).to eq("ok")
    end

    it "constructs the correct url for persistent connections" do
      stub_request(:get, "http://localhost/api/path?key=value")
        .to_return(status: 200, body: "ok")

      client = described_class.new(base_url: "http://localhost/api", token: "token").persistent

      expect(client.get("/path", params: { key: "value" }).to_s).to eq("ok")
    end

    [:get, :post, :put, :patch, :delete, :head, :options].each do |method|
      describe "##{method}" do
        it "calls with body" do
          stub_request(method, "http://localhost/api/path").with(body: { key: "value" }.to_json)
            .to_return(status: 200, body: "ok")

          client = described_class.new(base_url: "http://localhost/api", token: "token")

          expect(client.send(method, "/path", headers: { "Content-Type" => "application/json" }, body: { key: "value" }.to_json).to_s).to eq("ok")
        end
      end
    end

    describe "#close" do
      it "delegates to the request" do
        client = described_class.new(base_url: "http://localhost/", token: "token", base_request: HttpTestRequest.new)

        allow(client.instance_variable_get(:@request)).to receive(:close)

        client.close

        expect(client.instance_variable_get(:@request)).to have_received(:close)
      end
    end

    it "passes the token in the authorization header" do
      stub_request(:get, "http://localhost/api/path")
        .with(headers: { "Authorization" => "Bearer access_token" })
        .to_return(status: 200, body: "ok", headers: {})

      client = described_class.new(base_url: "http://localhost/api", token: "access_token")

      expect(client.get("/path").to_s).to eq("ok")
    end

    it "does not pass any authorization header when no token is provided" do
      stub_request(:get, "http://localhost/api/path")
        .with { |request| !request.headers.keys.map(&:to_s).map(&:downcase).include?("authorization") }
        .to_return(status: 200, body: "ok", headers: {})

      client = described_class.new(base_url: "http://localhost/api")

      expect(client.get("/path").to_s).to eq("ok")
    end

    it "calls token provider once if NullStore is set as cache" do
      stub_request(:get, "http://localhost/api/path")
        .to_return(status: 200, body: "ok")

      client = described_class.new(
        base_url: "http://localhost/api",
        token: described_class::TokenProvider.new(
          client_id: "client_id",
          client_secret: "client_secret",
          token_url: "http://localhost/oauth2/token",
          cache: ActiveSupport::Cache::NullStore.new
        )
      )

      expect(client.get("/path").to_s).to eq("ok")
      expect(auth_request_stub).to have_been_requested.once
    end

    it "retries the request when an http unauthorized status is returned" do
      stub_request(:get, "http://localhost/api/path")
        .to_return({ status: 401, body: "unauthorized" }, { status: 200, body: "ok" })

      client = described_class.new(
        base_url: "http://localhost/api",
        token: described_class::TokenProvider.new(
          client_id: "client_id",
          client_secret: "client_secret",
          token_url: "http://localhost/oauth2/token"
        )
      )

      expect(client.get("/path").to_s).to eq("ok")
    end

    it "raises if the retried request also fails" do
      stub_request(:get, "http://localhost/api/path")
        .to_return(status: 401, body: "unauthorized")

      client = described_class.new(
        base_url: "http://localhost/api",
        token: described_class::TokenProvider.new(
          client_id: "client_id",
          client_secret: "client_secret",
          token_url: "http://localhost/oauth2/token"
        )
      )

      expect { client.get("/path") }.to raise_error("Oauth2ApiClient::ResponseError::Unauthorized (401, http://localhost/api/path): unauthorized")
    end
  end
end
