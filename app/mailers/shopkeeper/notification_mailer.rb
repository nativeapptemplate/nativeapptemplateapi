class Shopkeeper::NotificationMailer < ShopkeeperMailer
  def invited
    @accounts_invitation = params[:accounts_invitation]
    @account = @accounts_invitation.account
    @invited_by = @accounts_invitation.invited_by

    name = @accounts_invitation.name
    email = @accounts_invitation.email

    mail(
      to: email_address_with_name(email, name),
      from: email_address_with_name(ConfigSettings.email.default_from, @invited_by.name),
      subject: I18n.t("shopkeeper.notification_mailer.invited.subject", inviter: @invited_by.name, account: @account.name)
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
end
