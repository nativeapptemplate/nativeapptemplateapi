# Preview at /rails/mailers/shopkeeper/notification_mailer (development);
# add ?locale=ja for Japanese. The records are built in memory, so the
# previews work on an empty database and save nothing
class Shopkeeper::NotificationMailerPreview < ActionMailer::Preview
  def invited
    shopkeeper = sample_shopkeeper
    invitation = AccountsInvitation.new(
      account: Account.new(name: "Sample Organization", owner: shopkeeper),
      name: "Invited Shopkeeper",
      email: "invited@example.com",
      token: "ABC123",
      invited_by: shopkeeper
    )
    Shopkeeper::NotificationMailer.with(accounts_invitation: invitation).invited
  end

  def confirmation_instructions
    Shopkeeper::NotificationMailer.with(resource: sample_shopkeeper, token: "sample-confirmation-token", opts: sample_opts).confirmation_instructions
  end

  def reset_password_instructions
    Shopkeeper::NotificationMailer.with(resource: sample_shopkeeper, token: "sample-reset-token", opts: sample_opts).reset_password_instructions
  end

  private

  def sample_shopkeeper
    Shopkeeper.new(name: "Sample Shopkeeper", email: "shopkeeper@example.com")
  end

  def sample_opts
    {redirect_url: "https://example.com", client_config: "default"}
  end
end
