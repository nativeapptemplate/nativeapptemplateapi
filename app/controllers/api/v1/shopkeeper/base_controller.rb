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

  def user_not_authorized
    render json: {code: 401, error_message: I18n.t("unauthorized")}, status: :unauthorized
  end
end
