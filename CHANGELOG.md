
# CHANGELOG

# v3.5.0

* Rescue `HTTP::Error` and raise `Oauth2ApiClient::Error` instead

# v3.4.1

* fix duplicate auth calls if NullStore is used

# v3.4.0

* Add PATCH method

# v3.3.0

* Add Oauth2ApiClient#params to set default query params

# v3.2.1

* Fix thread safety issue of http-rb

# v3.2.0

* Allow passing `nil` as token for unprotected APIs

# v3.1.1

* Added oauth2 version constraint

# v3.1.0

* Added uri to `Oauth2ApiClient::ReponseError` exception message

# v3.0.0

* [BREAKING] Renamed `Oauth2ApiClient::HttpError` to
  `Oauth2ApiClient::ResponseError`
* Added http error exception classes like e.g.
  `Oauth2ApiClient::ResponseError::NotFound`,
  `Oauth2ApiClient::ResponseError::InternalServerError`, etc.

# v2.1.0

* Include the response code and body in `HttpError#to_s`

# v2.0.0

* `TokenProvider` added
* Added option to pass the pre-generated oauth token
* Simple concatenation of base url and path
