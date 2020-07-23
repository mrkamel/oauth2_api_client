require File.expand_path("../spec_helper", __dir__)

RSpec.describe Oauth2ApiClient::ResponseError do
  describe "#to_s" do
    it "returns the message" do
      response = double(code: 401, body: "unauthorized")

      expect(described_class.new(response).to_s).to eq("Oauth2ApiClient::ResponseError (401): unauthorized")
    end
  end

  describe ".for" do
    it "returns the exception class for the status code of the given response" do
      expect(described_class.for(double(code: 400, body: "body"))).to be_instance_of(Oauth2ApiClient::ResponseError::BadRequest)
      expect(described_class.for(double(code: 404, body: "body"))).to be_instance_of(Oauth2ApiClient::ResponseError::NotFound)
      expect(described_class.for(double(code: 500, body: "body"))).to be_instance_of(Oauth2ApiClient::ResponseError::InternalServerError)
      expect(described_class.for(double(code: 503, body: "body"))).to be_instance_of(Oauth2ApiClient::ResponseError::ServiceUnavailable)
    end
  end
end
