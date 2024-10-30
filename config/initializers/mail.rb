# Assign the from email address in all environments
Rails.application.reloader.to_prepare do
  ActionMailer::Base.default_options = {from: ConfigSettings.email.default_from}

  if Rails.env.production? || Rails.env.staging?
    ActionMailer::Base.default_url_options[:host] = ConfigSettings.app.domain
    ActionMailer::Base.default_url_options[:protocol] = "https"

    shared_settings = {
      port: 587,
      authentication: :plain,
      enable_starttls_auto: true,
      domain: ConfigSettings.site.domain
    }

    settings = {
      address: Rails.application.credentials.dig(:smtp, :host),
      domain: Rails.application.credentials.dig(:smtp, :domain),
      user_name: Rails.application.credentials.dig(:smtp, :username),
      password: Rails.application.credentials.dig(:smtp, :password)
    }.merge(shared_settings)

    ActionMailer::Base.smtp_settings.merge!(settings)
  end
end
