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

  describe "request" do
    it "prepends the base url" do
      stub_request(:get, "http://localhost/api/path?key=value")
        .to_return(status: 200, body: "ok")

      client = described_class.new(base_url: "http://localhost/api", token: "token")

      expect(client.get("/path", params: { key: "value" }).to_s).to eq("ok")
    end

    it "passes the token in the authentication header" do
      stub_request(:get, "http://localhost/api/path")
        .with(headers: { "Authorization" => "Bearer access_token" })
        .to_return(status: 200, body: "ok", headers: {})

      client = described_class.new(base_url: "http://localhost/api", token: "access_token")

      expect(client.get("/path").to_s).to eq("ok")
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
