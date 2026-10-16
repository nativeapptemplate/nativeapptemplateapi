class Api::V1::Shopkeeper::Accounts::AccountsInvitationsController < Api::V1::Shopkeeper::BaseController
  # Each create or resend emails an address the caller chooses
  rate_limit to: 20, within: 1.hour, only: %i[create resend],
    name: "invitation_mails/shopkeeper",
    by: -> { current_shopkeeper.id },
    with: -> { render_error(code: 429, message: I18n.t("errors.messages.too_many_requests"), status: :too_many_requests) }

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
      render_validation_error(accounts_invitation)
    end
  end

  def update
    authorize @accounts_invitation

    if @accounts_invitation.update(invitation_params_update)
      render json: AccountsInvitationSerializer.new(@accounts_invitation).serializable_hash
    else
      render_validation_error(@accounts_invitation)
    end
  end

  def destroy
    authorize @accounts_invitation

    @accounts_invitation.destroy!
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
