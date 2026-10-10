class ShopkeeperAuth::SessionsController < DeviseTokenAuth::SessionsController
  RENDER_LOGIN_THROTTLED = -> {
    render json: {code: 429, error_message: I18n.t("errors.messages.too_many_logins")},
      status: :too_many_requests
  }
  private_constant :RENDER_LOGIN_THROTTLED

  rate_limit to: 5, within: 20.seconds, only: :create,
    name: "logins/ip",
    with: RENDER_LOGIN_THROTTLED

  rate_limit to: 5, within: 20.seconds, only: :create,
    name: "logins/email",
    by: -> { params[:email].to_s.downcase.gsub(/\s+/, "") },
    if: -> { params[:email].present? },
    with: RENDER_LOGIN_THROTTLED

  protected

  # devise_token_auth calls this only after the password checks out, so a
  # failed sign-in never writes the platform
  def render_create_success
    update_current_platform

    @resource.token = @token.token
    @resource.client = @token.client
    @resource.expiry = @token.expiry
    @resource.account_id = current_shopkeeper.personal_account.id

    render json: ShopkeeperSignInSerializer.new(@resource).serializable_hash, status: :ok
  end

  def render_create_error_not_confirmed
    render json: {code: 401, error_message: I18n.t("devise_token_auth.sessions.not_confirmed", email: @resource.email)}, status: :unauthorized
  end

  def render_create_error_bad_credentials
    render json: {code: 401, error_message: I18n.t("devise_token_auth.sessions.bad_credentials")}, status: :unauthorized
  end

  def render_destroy_success
    render json: {status: 200}, status: :ok
  end

  def render_destroy_error
    render json: {code: 404, error_message: I18n.t("devise_token_auth.sessions.user_not_found")}, status: :not_found
  end

  private

  # The apps send "ios" or "android"; anything else keeps the stored value
  def update_current_platform
    source = request.headers["source"]
    return unless Shopkeeper::CURRENT_PLATFORMS.include?(source)

    @resource.update_column(:current_platform, source)
  end
end
