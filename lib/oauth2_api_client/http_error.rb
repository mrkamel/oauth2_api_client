class Oauth2ApiClient
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
