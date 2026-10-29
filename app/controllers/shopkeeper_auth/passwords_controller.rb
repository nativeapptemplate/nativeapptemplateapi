class ShopkeeperAuth::PasswordsController < DeviseTokenAuth::PasswordsController
  include ActionController::MimeResponds
  include ActionController::Flash
  include SameHostRedirect
  include ThrottleMailRequests

  # Only the reset link's page (ShopkeeperAuth::ResetPasswordsController#edit) changes a
  # password here. With require_client_password_reset_token, devise_token_auth's update
  # never checks the current password, so a request signed in with just the access token
  # could set a new one without knowing the old; and a current_password it was sent
  # reached `update` and failed with a 500. The apps change the password with
  # PATCH /api/v1/shopkeeper/account/password, which asks for the current one.
  before_action :require_reset_password_token, only: :update

  protected

  # The value devise_token_auth's update reads (resource_params permits only a string):
  # a token sent as an array or a hash would pass a check of params here, yet be nil
  # there, and update would fall back to the access token
  def require_reset_password_token
    return if resource_params[:reset_password_token].present?

    render json: {code: 401, error_message: I18n.t("unauthorized")}, status: :unauthorized
  end

  # Checked by devise_token_auth for both the reset request and the emailed link
  def blacklisted_redirect_url?(redirect_url)
    !same_host_url?(redirect_url)
  end

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
    render json: {success: true, message: I18n.t("devise_token_auth.passwords.sended_paranoid")}, status: :ok
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
    redirect_to(
      edit_shopkeeper_auth_reset_password_path(
        reset_password_token: params[:reset_password_token]
      ),
      alert: @resource.errors.full_messages.to_sentence
    )
  end
end
