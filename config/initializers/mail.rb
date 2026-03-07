# Assign the from email address in all environments
Rails.application.reloader.to_prepare do
  ActionMailer::Base.default_options = {from: ConfigSettings.email.default_from}

  if Rails.env.production? || Rails.env.staging?
    ActionMailer::Base.default_url_options[:host] = ConfigSettings.app.domain
    ActionMailer::Base.default_url_options[:protocol] = "https"

    ActionMailer::Base.delivery_method = :resend
    Resend.api_key = Rails.application.credentials.dig(:resend, :api_key)
  end
end
