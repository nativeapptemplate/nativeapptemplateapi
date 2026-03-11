class Api::V1::Shopkeeper::Accounts::AccountsInvitationsController < Api::V1::Shopkeeper::BaseController
  before_action :set_account
  before_action :require_account_admin, except: %i[index show]
  before_action :set_accounts_invitation, only: %i[show update destroy resend]
  skip_after_action :verify_authorized

  def index
    @accounts_invitations = @account.accounts_invitations.order(name: :asc)
    render json: AccountsInvitationSerializer.new(@accounts_invitations).serializable_hash
  end

  def show
    options = {}
    options[:include] = [:account, :invited_by]
    render json: AccountsInvitationSerializer.new(@accounts_invitation, options).serializable_hash
  end

  def create
    accounts_invitation = @account.accounts_invitations.build(invitation_params_create)

    if accounts_invitation.save_and_send_invite
      render json: AccountsInvitationSerializer.new(accounts_invitation).serializable_hash, status: :created
    else
      render json: {code: 422, error_message: accounts_invitation.errors.full_messages.to_sentence}, status: :unprocessable_entity
    end
  end

  def update
    if @accounts_invitation.update(invitation_params_update)
      render json: AccountsInvitationSerializer.new(@accounts_invitation).serializable_hash
    else
      render json: {code: 422, error_message: @accounts_invitation.errors.full_messages.to_sentence}, status: :unprocessable_entity
    end
  end

  def destroy
    @accounts_invitation.destroy
    render json: {status: 200}, status: :ok
  end

  def resend
    @accounts_invitation.resend_invite
    render json: {status: 200}, status: :ok
  end

  private

  def set_account
    @account = current_shopkeeper.accounts.find(params[:account_id])
  end

  def set_accounts_invitation
    @accounts_invitation = @account.accounts_invitations.find_by!(token: params[:id])
  end

  def invitation_params_create
    params
      .require(:accounts_invitation)
      .permit(:name, :email, AccountsShopkeeper::ROLES)
      .merge(invited_by: current_shopkeeper)
  end

  def invitation_params_update
    params
      .require(:accounts_invitation)
      .permit(:name, AccountsShopkeeper::ROLES)
  end

  def require_account_admin
    accounts_shopkeeper = @account.accounts_shopkeepers.find_by(shopkeeper: current_shopkeeper)
    return if accounts_shopkeeper&.admin?

    render json: {code: 401, error_message: I18n.t("api.shopkeeper.accounts.admin_required")}, status: :unauthorized
  end
end
