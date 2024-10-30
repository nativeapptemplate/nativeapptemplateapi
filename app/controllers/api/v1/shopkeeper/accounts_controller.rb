class Api::V1::Shopkeeper::AccountsController < Api::V1::Shopkeeper::BaseController
  before_action :set_account, only: %i[show update destroy]
  before_action :require_account_admin, only: %i[update]
  before_action :require_account_owner, only: %i[destroy]
  before_action :prevent_personal_account_deletion, only: %i[destroy]
  skip_after_action :verify_authorized

  # GET /accounts
  def index
    accounts = current_shopkeeper.accounts.sorted
    options = {
      params: {current_shopkeeper: current_shopkeeper}
    }

    created_accounts_count = current_shopkeeper.owned_accounts.size

    options[:meta] = {
      limit_count: ConfigSettings.account.limit_count,
      created_accounts_count: created_accounts_count
    }

    render json: AccountSerializer.new(accounts, options).serializable_hash
  end

  # GET /accounts/1
  def show
    options = {
      include: [:accounts_shopkeepers, :accounts_invitations],
      params: {current_shopkeeper: current_shopkeeper}
    }
    render json: AccountSerializer.new(@account, options).serializable_hash
  end

  # POST /accounts
  def create
    account = Account.new(account_params.merge(owner: current_shopkeeper))
    account.accounts_shopkeepers.new(shopkeeper: current_shopkeeper, admin: true)

    if account.save
      options = {
        params: {current_shopkeeper: current_shopkeeper}
      }

      render json: AccountSerializer.new(account, options).serializable_hash, status: :created
    else
      render json: {code: 422, error_message: account.errors.full_messages.to_sentence}, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /accounts/1
  def update
    if @account.update(account_params)
      options = {
        params: {current_shopkeeper: current_shopkeeper}
      }
      render json: AccountSerializer.new(@account, options).serializable_hash
    else
      render json: {code: 422, error_message: @account.errors.full_messages.to_sentence}, status: :unprocessable_entity
    end
  end

  # DELETE /accounts/1
  def destroy
    ActsAsTenant.without_tenant do
      @account.destroy
    end

    render json: {status: 200}, status: :ok
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_account
    @account = current_shopkeeper.accounts.find(params[:id])
  end

  # Only allow a trusted parameter "white list" through.
  def account_params
    params.require(:account).permit(:name)
  end

  def prevent_personal_account_deletion
    return unless @account.personal?

    render json: {code: 422, error_message: I18n.t("api.shopkeeper.accounts.personal.cannot_delete")}, status: :unprocessable_entity
  end

  def require_account_admin
    accounts_shopkeeper = @account.accounts_shopkeepers.find_by(shopkeeper: current_shopkeeper)
    return if accounts_shopkeeper&.admin?

    render json: {code: 401, error_message: I18n.t("api.shopkeeper.accounts.admin_required")}, status: :unauthorized
  end

  def require_account_owner
    return if @account.owner?(current_shopkeeper)

    render json: {code: 401, error_message: I18n.t("api.shopkeeper.accounts.owner_required")}, status: :unauthorized
  end
end
