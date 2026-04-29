class Api::V1::Shopkeeper::PermissionsController < Api::V1::Shopkeeper::BaseController
  def index
    authorize Permission

    current_ios_app_version = AppVersion.forced_update.current_version(platform: "ios")
    current_android_app_version = AppVersion.forced_update.current_version(platform: "android")

    current_privacy_version = PrivacyVersion.current_version
    current_terms_version = TermsVersion.current_version

    should_update_privacy = current_shopkeeper.confirmed_privacy_version < current_privacy_version
    should_update_terms = current_shopkeeper.confirmed_terms_version < current_terms_version

    options = {}
    options[:meta] = {
      ios_app_version: current_ios_app_version,
      android_app_version: current_android_app_version,
      should_update_privacy: should_update_privacy,
      should_update_terms: should_update_terms,
      shop_limit_count: ConfigSettings.shop.limit_count,
      account_limit_count: ConfigSettings.account.limit_count,
      accounts_shopkeeper_limit_count: ConfigSettings.accounts_shopkeeper.limit_count
    }

    permissions = current_accounts_shopkeeper.permissions
    render json: PermissionSerializer.new(permissions, options).serializable_hash
  end
end
