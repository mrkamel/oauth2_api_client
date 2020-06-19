class Oauth2ApiClient
  class HttpError < StandardError
    attr_reader :message, :response

    def initialize(message, response)
      @message = message
      @response = response
    end
  end
end
