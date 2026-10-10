class NonApiApplicationController < ActionController::Base
  include SetLocale

  allow_browser versions: :modern
  protect_from_forgery with: :exception

  rate_limit to: ApplicationController::REQUESTS_PER_IP_LIMIT, within: ApplicationController::REQUESTS_PER_IP_WINDOW,
    scope: :requests_per_ip
end
