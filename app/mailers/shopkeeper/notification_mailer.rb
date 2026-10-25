class Shopkeeper::NotificationMailer < ShopkeeperMailer
  def invited
    @accounts_invitation = params[:accounts_invitation]
    @account = @accounts_invitation.account
    # invited_by is nullified when the inviter is deleted; the invitation can
    # still be resent, so name the app instead
    @inviter_name = @accounts_invitation.invited_by&.name || ConfigSettings.display_name
    @store_links = store_links
    # Opens the invitation in the app (Universal Links / App Links, served from
    # this API's host: config/settings.yml app_links). The code and the steps
    # stay for when it can't
    @invitation_url = "https://#{ConfigSettings.app.domain}/invitations/#{@accounts_invitation.token}"

    name = @accounts_invitation.name
    email = @accounts_invitation.email

    # From stays the app (ApplicationMailer's default): the inviter's name is
    # free text, so it goes in the subject and body only
    mail(
      to: email_address_with_name(email, name),
      subject: I18n.t("shopkeeper.notification_mailer.invited.subject", inviter: @inviter_name, account: @account.name)
    )
  end

  def confirmation_instructions
    @resource = params[:resource]
    @token = params[:token]
    @redirect_url = params[:opts][:redirect_url]
    @client_config = params[:opts][:client_config]

    name = @resource.name
    @email = params[:opts][:to] || @resource.email

    mail(
      to: email_address_with_name(@email, name),
      subject: I18n.t("shopkeeper.notification_mailer.confirmation_instructions.subject")
    )
  end

  def reset_password_instructions
    @resource = params[:resource]
    @token = params[:token]
    @redirect_url = params[:opts][:redirect_url]
    @client_config = params[:opts][:client_config]

    name = @resource.name
    email = @resource.email

    mail(
      to: email_address_with_name(email, name),
      subject: I18n.t("shopkeeper.notification_mailer.reset_password_instructions.subject")
    )
  end

  private

  # Blank store URLs (the default in config/settings.yml) are left out, so
  # the mail never links a placeholder before the apps are published
  def store_links
    app = ConfigSettings.display_name
    {
      I18n.t("shopkeeper.notification_mailer.invited.ios_app", mobile_app: app) => ConfigSettings.mobile_app.app_store_url,
      I18n.t("shopkeeper.notification_mailer.invited.android_app", mobile_app: app) => ConfigSettings.mobile_app.play_store_url
    }.select { |_label, url| url.present? }
  end
end
