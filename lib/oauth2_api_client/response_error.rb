class Oauth2ApiClient
  # The ResponseError class is the main exception class of Oauth2ApiClient and is
  # raised when a request fails with some status code other than 2xx. Using
  # the exception object, you still have access to the response. Moreover,
  # there are exception classes for all 4xx and 5xx errors.
  #
  # @example
  #   begin
  #     client.post("/orders", json: { address: "..." })
  #   rescue Oauth2ApiClient::ResponseError::NotFound => e
  #     e.response # => HTTP::Response
  #   rescue Oauth2ApiClient::ResponseError::BadRequest => e
  #     # ...
  #   rescue Oauth2ApiClient::ResponseError => e
  #     # ...
  #   end

  class ResponseError < StandardError
    STATUSES = {
      400 => "Bad Request",
      401 => "Unauthorized",
      402 => "Payment Required",
      403 => "Forbidden",
      404 => "Not Found",
      405 => "Method Not Allowed",
      406 => "Not Acceptable",
      407 => "Proxy Authentication Required",
      408 => "Request Timeout",
      409 => "Conflict",
      410 => "Gone",
      411 => "Length Required",
      412 => "Precondition Failed",
      413 => "Payload Too Large",
      414 => "URI Too Long",
      415 => "Unsupported Media Type",
      416 => "Range Not Satisfiable",
      417 => "Expectation Failed",
      418 => "I'm A Teapot",
      421 => "Too Many Connections From This IP",
      422 => "Unprocessable Entity",
      423 => "Locked",
      424 => "Failed Dependency",
      425 => "Unordered Collection",
      426 => "Upgrade Required",
      428 => "Precondition Required",
      429 => "Too Many Requests",
      431 => "Request Header Fields Too Large",
      449 => "Retry With",
      450 => "Blocked By Windows Parental Controls",

      500 => "Internal Server Error",
      501 => "Not Implemented",
      502 => "Bad Gateway",
      503 => "Service Unavailable",
      504 => "Gateway Timeout",
      505 => "HTTP Version Not Supported",
      506 => "Variant Also Negotiates",
      507 => "Insufficient Storage",
      508 => "Loop Detected",
      509 => "Bandwidth Limit Exceeded",
      510 => "Not Extended",
      511 => "Network Authentication Required"
    }

    attr_reader :response

    def initialize(response)
      @response = response
    end

    def to_s
      "#{self.class.name} (#{response.code}, #{response.uri}): #{response.body}"
    end

    # @api private
    #
    # Returns the exception class for a status code of the given response.

    def self.for(response)
      return const_get(const_name(STATUSES[response.code])).new(response) if STATUSES.key?(response.code)

      new(response)
    end

    # @api private
    #
    # Returns a sanitized version to be used as a constant name for a given
    # http error message.

    def self.const_name(message)
      message.gsub(/[^a-zA-Z0-9]/, "")
    end

    STATUSES.each do |_code, message|
      const_set(const_name(message), Class.new(self))
    end
  end
end
