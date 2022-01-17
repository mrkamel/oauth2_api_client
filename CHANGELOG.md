
# CHANGELOG

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
