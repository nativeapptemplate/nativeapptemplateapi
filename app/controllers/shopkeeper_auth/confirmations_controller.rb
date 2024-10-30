class ShopkeeperAuth::ConfirmationsController < DeviseTokenAuth::ConfirmationsController
  protected

  def render_create_error_missing_email
    render json: {code: 401, error_message: I18n.t("devise_token_auth.confirmations.missing_email")}, status: :unauthorized
  end

  def render_not_found_error
    render json: {code: 404, error_message: I18n.t("devise_token_auth.confirmations.user_not_found", email: @email)}, status: :not_found
  end

  private

  # give redirect value from params priority or fall back to default value if provided
  def redirect_url
    params.fetch(
      :redirect_url,
      shopkeeper_auth_confirmation_result_url
    )
  end
end
