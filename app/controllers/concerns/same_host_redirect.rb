# devise_token_auth redirects to a client-supplied redirect_url, appending reset
# and confirmation tokens. The mobile apps send the API's own base URL, so only
# a URL on the host serving this request is allowed. Comparing with
# request.host works on production, PR previews and development alike.
module SameHostRedirect
  private

  def same_host_url?(url)
    URI.parse(url.to_s).host&.casecmp?(request.host) || false
  rescue URI::InvalidURIError
    false
  end
end
