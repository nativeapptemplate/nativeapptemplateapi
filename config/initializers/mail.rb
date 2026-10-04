# Assign the from email address in all environments
Rails.application.reloader.to_prepare do
  ActionMailer::Base.default_options = {from: ConfigSettings.email.default_from}

  if Rails.env.production? || Rails.env.staging?
    # PR previews (staging) set their own Render host in staging.rb. Their emails
    # must link back to that preview, whose tokens don't exist in production.
    ActionMailer::Base.default_url_options[:host] =
      Rails.application.routes.default_url_options[:host] || ConfigSettings.app.domain
    ActionMailer::Base.default_url_options[:protocol] = "https"

    ActionMailer::Base.delivery_method = :resend
    Resend.api_key = Rails.application.credentials.dig(:resend, :api_key)
  end
end
