class Api::V1::Shopkeeper::BaseController < ApplicationController
  include DeviseTokenAuth::Concerns::SetUserByToken
  include SetCurrentRequestDetails
  include Pundit::Authorization
  include CurrentShopkeeperHelper
  include Pagination

  before_action :authenticate_shopkeeper!
  before_action -> { use_locale_of(current_shopkeeper) }
  after_action :verify_authorized

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActiveRecord::RecordNotDestroyed, with: :record_not_destroyed
  rescue_from ActionController::ParameterMissing, with: :parameter_missing
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def pundit_user
    current_accounts_shopkeeper
  end

  def policy_scope(scope)
    super([:api, :shopkeeper, scope])
  end

  def authorize(record, query = nil)
    super([:api, :shopkeeper, record], query)
  end

  private

  def render_validation_error(record)
    render json: {code: 422, error_message: record.errors.full_messages.to_sentence}, status: :unprocessable_entity
  end

  def render_error(code:, message:, status:)
    render json: {code: code, error_message: message}, status: status
  end

  def user_not_authorized
    render_error(code: 401, message: I18n.t("unauthorized"), status: :unauthorized)
  end

  def record_not_found
    render_error(code: 404, message: I18n.t("not_found"), status: :not_found)
  end

  # destroy! raises this when a before_destroy callback halts the destroy
  def record_not_destroyed(error)
    message = error.record.errors.full_messages.to_sentence.presence || I18n.t("not_destroyed")
    render_error(code: 422, message: message, status: :unprocessable_entity)
  end

  def parameter_missing
    render_error(code: 400, message: I18n.t("bad_request"), status: :bad_request)
  end
end
