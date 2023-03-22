lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "oauth2_api_client/version"

Gem::Specification.new do |spec|
  spec.name          = "oauth2_api_client"
  spec.version       = Oauth2ApiClient::VERSION
  spec.authors       = ["Benjamin Vetter"]
  spec.email         = ["vetter@flakks.com"]
  spec.description   = "Small but powerful client around oauth2 and http-rb to interact with APIs"
  spec.summary       = "Small but powerful client around oauth2 and http-rb to interact with APIs"
  spec.homepage      = "https://github.com/mrkamel/oauth2_api_client"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport"
  spec.add_dependency "http"
  spec.add_dependency "oauth2", ">= 1.4.2"
  spec.add_dependency "ruby2_keywords"
end
