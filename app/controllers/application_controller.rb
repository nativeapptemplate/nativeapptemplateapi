class ApplicationController < ActionController::API
  include SetLocale

  # Per-IP cap on every API and auth request, shared with the HTML pages
  # through the scope. Sign-in, sign-up and invitation lookups add tighter
  # limits of their own.
  REQUESTS_PER_IP_LIMIT = 300
  REQUESTS_PER_IP_WINDOW = 5.minutes

  rate_limit to: REQUESTS_PER_IP_LIMIT, within: REQUESTS_PER_IP_WINDOW, scope: :requests_per_ip,
    with: -> { render json: {code: 429, error_message: I18n.t("errors.messages.too_many_requests")}, status: :too_many_requests }
end
