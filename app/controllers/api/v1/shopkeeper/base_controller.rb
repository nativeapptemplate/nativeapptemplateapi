class Api::V1::Shopkeeper::BaseController < ApplicationController
  include DeviseTokenAuth::Concerns::SetUserByToken
  include SetCurrentRequestDetails
  include Pundit::Authorization
  include CurrentShopkeeperHelper

  before_action :authenticate_shopkeeper!
  after_action :verify_authorized

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
end
