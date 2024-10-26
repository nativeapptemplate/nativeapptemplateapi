# Be sure to restart your server when you modify this file.

# Configure parameters to be partially matched (e.g. passw matches password) and filtered from the log file.
# Use this to limit dissemination of sensitive information.
# See the ActiveSupport::ParameterFilter documentation for supported notations and behaviors.
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn,
  :otp_attempt,
  :name,
  :first_name,
  :last_name,
  :current_sign_in_ip,
  :last_sign_in_ip,
  :access_token,
  :access_token_secret,
  :refresh_token
]
