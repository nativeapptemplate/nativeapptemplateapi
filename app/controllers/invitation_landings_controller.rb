# Where the invitation mail's link lands when the app does not open it: not
# installed, or opened somewhere that keeps links in the browser. The code is
# neither shown nor looked up; the mail has it with the steps.
class InvitationLandingsController < NonApiApplicationController
  layout "minimal"

  def show
    app = ConfigSettings.display_name
    @store_links = {
      t("shopkeeper.notification_mailer.invited.ios_app", mobile_app: app) => ConfigSettings.mobile_app.app_store_url,
      t("shopkeeper.notification_mailer.invited.android_app", mobile_app: app) => ConfigSettings.mobile_app.play_store_url
    }.select { |_label, url| url.present? }
  end
end
