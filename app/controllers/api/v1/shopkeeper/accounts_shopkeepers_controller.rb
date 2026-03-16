class Api::V1::Shopkeeper::AccountsShopkeepersController < Api::V1::Shopkeeper::BaseController
  before_action :set_account
  before_action :require_non_personal_account!, only: %i[show update destroy]
  before_action :set_accounts_shopkeeper, only: %i[show update destroy]
  before_action :safeguard_account_owner_deletion!, only: %i[destroy]

  def index
    authorize AccountsShopkeeper

    if @account.personal?
      render json: AccountsShopkeeperSerializer.new([]).serializable_hash and return
    end

    @accounts_shopkeepers = @account.accounts_shopkeepers.joins(:shopkeeper).includes(:shopkeeper).order("shopkeepers.name ASC")

    options = {}
    options[:include] = [:account, :shopkeeper]
    render json: AccountsShopkeeperSerializer.new(@accounts_shopkeepers, options).serializable_hash
  end

  def show
    authorize @accounts_shopkeeper

    options = {}
    options[:include] = [:account, :shopkeeper]

    render json: AccountsShopkeeperSerializer.new(@accounts_shopkeeper, options).serializable_hash
  end

  def update
    authorize @accounts_shopkeeper

    if @accounts_shopkeeper.update(accounts_shopkeeper_params)
      options = {}
      options[:include] = [:account, :shopkeeper]

      render json: AccountsShopkeeperSerializer.new(@accounts_shopkeeper, options).serializable_hash
    else
      render_validation_error(@accounts_shopkeeper)
    end
  end

  def destroy
    authorize @accounts_shopkeeper

    @accounts_shopkeeper.destroy
    render json: {status: 200}, status: :ok
  end

  private

  def pundit_user
    @account.accounts_shopkeepers.find_by!(shopkeeper: current_shopkeeper)
  end

  def set_account
    @account = current_shopkeeper.accounts.find(params[:account_id])
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_accounts_shopkeeper
    @accounts_shopkeeper = @account.accounts_shopkeepers.find(params[:id])
  end

  # Only allow a trusted parameter "white list" through.
  def accounts_shopkeeper_params
    params.require(:accounts_shopkeeper).permit(*AccountsShopkeeper::ROLES)
  end

  def require_non_personal_account!
    return unless @account.personal?

    render_error(code: 422, message: I18n.t("api.shopkeeper.accounts_shopkeepers.require_non_personal_account"), status: :unprocessable_entity)
  end

  def safeguard_account_owner_deletion!
    return unless @accounts_shopkeeper.account_owner?

    render_error(code: 401, message: I18n.t("unauthorized"), status: :unauthorized)
  end
end
