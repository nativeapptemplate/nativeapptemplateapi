class ShopkeeperAuth::ConfirmationsController < DeviseTokenAuth::ConfirmationsController
  include SameHostRedirect

  protected

  def render_create_error_missing_email
    render json: {code: 401, error_message: I18n.t("devise_token_auth.confirmations.missing_email")}, status: :unauthorized
  end

  def render_not_found_error
    render json: {code: 404, error_message: I18n.t("devise_token_auth.confirmations.user_not_found", email: @email)}, status: :not_found
  end

  private

  # Used for the emailed link and the redirect after confirming. A redirect_url
  # on another host falls back to the default instead of being followed.
  def redirect_url
    url = params[:redirect_url]
    same_host_url?(url) ? url : shopkeeper_auth_confirmation_result_url
  end
end
