# Answers an /<account uuid>/api/... request whose organization no longer
# exists. AccountMiddleware dispatches here directly (there is no route), so
# the client gets JSON whatever its Accept or Content-Type, and can tell this
# apart from other 404s by error_code and switch to its personal organization.
#
# The token is checked only to pick the language: a signed-in shopkeeper gets
# their saved locale, anyone else Accept-Language (SetLocale).
class Api::V1::Shopkeeper::AccountNotFoundController < ApplicationController
  include DeviseTokenAuth::Concerns::SetUserByToken

  def show
    use_locale_of(current_shopkeeper)
    render json: {code: 404, error_code: "account_not_found", error_message: I18n.t("api.shopkeeper.account_not_found")},
      status: :not_found
  end
end
