class Api::V1::Shopkeeper::AccountsInvitationsController < Api::V1::Shopkeeper::BaseController
  before_action :set_accounts_invitation

  def show
    authorize @accounts_invitation, :show_by_token?

    if @accounts_invitation.expired?
      render json: {code: 410, error_message: I18n.t("api.shopkeeper.accounts_invitations.expired")}, status: :gone
      return
    end

    options = {}
    options[:include] = [:account, :invited_by]
    render json: AccountsInvitationSerializer.new(@accounts_invitation, options).serializable_hash
  end

  def update
    authorize @accounts_invitation, :accept?

    if @accounts_invitation.expired?
      render json: {code: 410, error_message: I18n.t("api.shopkeeper.accounts_invitations.expired")}, status: :gone
      return
    end

    if @accounts_invitation.accept!(current_shopkeeper)
      render json: {status: 200}, status: :ok
    else
      error_message = @accounts_invitation.errors.full_messages.first || I18n.t("something_went_wrong")
      render json: {code: 422, error_message: error_message}, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @accounts_invitation, :reject?

    @accounts_invitation.reject!
    render json: {status: 200}, status: :ok
  end

  private

  def set_accounts_invitation
    @accounts_invitation = AccountsInvitation.find_by!(token: params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {code: 404, error_message: I18n.t("api.shopkeeper.accounts_invitations.not_found")}, status: :not_found
  end
end
