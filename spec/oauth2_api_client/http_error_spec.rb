require File.expand_path("../spec_helper", __dir__)

RSpec.describe Oauth2ApiClient::HttpError do
  describe "#to_s" do
    it "returns the message" do
      response = double(code: 401, body: "unauthorized")

      expect(described_class.new(response).to_s).to eq("Oauth2ApiClient::HttpError (401): unauthorized")
    end
  end
end
