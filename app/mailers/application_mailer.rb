class ApplicationMailer < ActionMailer::Base
  default from: ConfigSettings.email.default_from_with_name
  layout "mailer"

  # Include any view helpers from your main app to use in mailers here
  helper ApplicationHelper
end
