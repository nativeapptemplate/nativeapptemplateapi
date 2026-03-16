class Api::V1::Shopkeeper::AccountsController < Api::V1::Shopkeeper::BaseController
  before_action :set_account, only: %i[show update destroy]
  before_action :prevent_personal_account_deletion, only: %i[destroy]

  # GET /accounts
  def index
    authorize Account

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
    authorize @account

    options = {
      include: [:accounts_shopkeepers, :accounts_invitations],
      params: {current_shopkeeper: current_shopkeeper}
    }
    render json: AccountSerializer.new(@account, options).serializable_hash
  end

  # POST /accounts
  def create
    authorize Account

    account = Account.new(account_params.merge(owner: current_shopkeeper))
    account.accounts_shopkeepers.new(shopkeeper: current_shopkeeper, admin: true)

    if account.save
      options = {
        params: {current_shopkeeper: current_shopkeeper}
      }

      render json: AccountSerializer.new(account, options).serializable_hash, status: :created
    else
      render_validation_error(account)
    end
  end

  # PATCH/PUT /accounts/1
  def update
    authorize @account

    if @account.update(account_params)
      options = {
        params: {current_shopkeeper: current_shopkeeper}
      }
      render json: AccountSerializer.new(@account, options).serializable_hash
    else
      render_validation_error(@account)
    end
  end

  # DELETE /accounts/1
  def destroy
    authorize @account

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

  def pundit_user
    if @account
      @account.accounts_shopkeepers.find_by!(shopkeeper: current_shopkeeper)
    else
      super
    end
  end

  def prevent_personal_account_deletion
    return unless @account.personal?

    render_error(code: 422, message: I18n.t("api.shopkeeper.accounts.personal.cannot_delete"), status: :unprocessable_entity)
  end
end
