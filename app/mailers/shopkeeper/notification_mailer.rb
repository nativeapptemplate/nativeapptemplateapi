class Shopkeeper::NotificationMailer < ShopkeeperMailer
  def invited
    @accounts_invitation = params[:accounts_invitation]
    @account = @accounts_invitation.account
    # invited_by is nullified when the inviter is deleted; the invitation can
    # still be resent, so name the app instead
    @inviter_name = @accounts_invitation.invited_by&.name || ConfigSettings.display_name
    @store_links = store_links

    name = @accounts_invitation.name
    email = @accounts_invitation.email

    mail(
      to: email_address_with_name(email, name),
      from: email_address_with_name(ConfigSettings.email.default_from, @inviter_name),
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
