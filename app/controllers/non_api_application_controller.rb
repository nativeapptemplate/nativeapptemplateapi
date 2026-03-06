class NonApiApplicationController < ActionController::Base
  allow_browser versions: :modern
  protect_from_forgery with: :exception
end
