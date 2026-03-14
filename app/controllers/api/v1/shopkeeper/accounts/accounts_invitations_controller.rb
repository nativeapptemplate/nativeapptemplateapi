class Api::V1::Shopkeeper::Accounts::AccountsInvitationsController < Api::V1::Shopkeeper::BaseController
  before_action :set_account
  before_action :set_accounts_invitation, only: %i[show update destroy resend]

  def index
    authorize AccountsInvitation

    @accounts_invitations = @account.accounts_invitations.order(name: :asc)
    render json: AccountsInvitationSerializer.new(@accounts_invitations).serializable_hash
  end

  def show
    authorize @accounts_invitation

    options = {}
    options[:include] = [:account, :invited_by]
    render json: AccountsInvitationSerializer.new(@accounts_invitation, options).serializable_hash
  end

  def create
    authorize AccountsInvitation

    accounts_invitation = @account.accounts_invitations.build(invitation_params_create)

    if accounts_invitation.save_and_send_invite
      render json: AccountsInvitationSerializer.new(accounts_invitation).serializable_hash, status: :created
    else
      render json: {code: 422, error_message: accounts_invitation.errors.full_messages.to_sentence}, status: :unprocessable_entity
    end
  end

  def update
    authorize @accounts_invitation

    if @accounts_invitation.update(invitation_params_update)
      render json: AccountsInvitationSerializer.new(@accounts_invitation).serializable_hash
    else
      render json: {code: 422, error_message: @accounts_invitation.errors.full_messages.to_sentence}, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @accounts_invitation

    @accounts_invitation.destroy
    render json: {status: 200}, status: :ok
  end

  def resend
    authorize @accounts_invitation

    @accounts_invitation.resend_invite
    render json: {status: 200}, status: :ok
  end

  private

  def pundit_user
    @account.accounts_shopkeepers.find_by!(shopkeeper: current_shopkeeper)
  end

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
end
