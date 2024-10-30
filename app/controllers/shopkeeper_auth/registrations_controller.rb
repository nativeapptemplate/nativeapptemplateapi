class ShopkeeperAuth::RegistrationsController < DeviseTokenAuth::RegistrationsController
  before_action :set_confirm_success_url, only: %i[create]
  before_action :configure_permitted_parameters

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[name email password time_zone current_platform])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[name email time_zone])
  end

  def render_create_success
    @resource.token = @token.token
    @resource.client = @token.client
    @resource.expiry = @token.expiry
    @resource.account_id = current_shopkeeper.personal_account.id

    @resource.confirmed_privacy_version = PrivacyVersion.current_version
    @resource.confirmed_terms_version = TermsVersion.current_version
    @resource.save!(validate: false)

    render json: ShopkeeperSignInSerializer.new(@resource).serializable_hash, status: :ok
  end

  def render_update_success
    @resource.account_id = "DUMMY_ACCOUNT_ID"

    render json: ShopkeeperSignInSerializer.new(@resource).serializable_hash, status: :ok
  end

  def render_destroy_success
    render json: {status: 200}, status: :ok
  end

  def render_create_error
    render json: {code: 422, error_message: @resource.errors.full_messages.to_sentence}, status: :unprocessable_entity
  end

  def render_update_error
    render json: {code: 422, error_message: @resource.errors.full_messages.to_sentence}, status: :unprocessable_entity
  end

  def render_destroy_error
    render json: {code: 422, error_message: @resource.errors.full_messages.to_sentence}, status: :unprocessable_entity
  end

  private

  def validate_sign_up_params
    return if sign_up_params.present?

    render json: {code: 422, error_message: I18n.t("errors.messages.validate_sign_up_params")}, status: :unprocessable_entity
  end

  def validate_account_update_params
    return if account_update_params.present?

    render json: {code: 422, error_message: I18n.t("errors.messages.validate_account_update_params")}, status: :unprocessable_entity
  end

  def set_confirm_success_url
    params[:confirm_success_url] = shopkeeper_auth_confirmation_result_url
  end
end
