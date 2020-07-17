class Oauth2ApiClient
  # The HttpError class is the main exception class of Oauth2ApiClient and is
  # raised when a request fails with some status code other than 2xx. Using
  # the exception object, you still have access to the response.
  #
  # @example
  #   begin
  #     client.post("/orders", json: { address: "..." })
  #   rescue Oauth2ApiClient::HttpError => e
  #     e.response # => HTTP::Response
  #   end

  class HttpError < StandardError
    attr_reader :response

    def initialize(response)
      @response = response
    end

    def to_s
      "#{self.class.name} (#{response.code}): #{response.body}"
    end
  end
end
