class ShopkeeperAuth::PasswordsController < DeviseTokenAuth::PasswordsController
  include ActionController::MimeResponds
  include ActionController::Flash

  protected

  def render_create_error_missing_email
    render json: {code: 401, error_message: I18n.t("devise_token_auth.passwords.missing_email")}, status: :unauthorized
  end

  def render_create_error_missing_redirect_url
    render json: {code: 401, error_message: I18n.t("devise_token_auth.passwords.missing_redirect_url")}, status: :unauthorized
  end

  def render_error_not_allowed_redirect_url
    message = I18n.t("devise_token_auth.passwords.not_allowed_redirect_url", redirect_url: @redirect_url)
    render json: {code: 422, error_message: message}, status: :unprocessable_entity
  end

  def render_not_found_error
    render json: {code: 404, error_message: I18n.t("devise_token_auth.passwords.user_not_found", email: @email)}, status: :not_found
  end

  def render_create_error(errors)
    render json: {code: 400, error_message: errors.full_messages.to_sentence}, status: :bad_request
  end

  def render_update_success
    redirect_to shopkeeper_auth_reset_password_path
  end

  def render_update_error_unauthorized
    redirect_to(
      edit_shopkeeper_auth_reset_password_path(
        reset_password_token: params[:reset_password_token]
      ),
      alert: I18n.t("unauthorized")
    )
  end

  def render_update_error_missing_password
    redirect_to(
      edit_shopkeeper_auth_reset_password_path(
        reset_password_token: params[:reset_password_token]
      ),
      alert: I18n.t("devise_token_auth.passwords.missing_passwords")
    )
  end

  def render_update_error
    error_messages = @resource.errors.full_messages.flatten.join("<br/>").html_safe

    redirect_to(
      edit_shopkeeper_auth_reset_password_path(
        reset_password_token: params[:reset_password_token]
      ),
      alert: error_messages
    )
  end
end
