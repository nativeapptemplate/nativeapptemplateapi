class Api::V1::Shopkeeper::MeController < Api::V1::Shopkeeper::BaseController
  before_action :set_shopkeeper, only: %i[update_confirmed_privacy_version update_confirmed_terms_version]
  skip_after_action :verify_authorized

  def update_confirmed_privacy_version
    @shopkeeper.confirmed_privacy_version = PrivacyVersion.current_version
    @shopkeeper.save!(validate: false)
    render json: {status: 200}, status: :ok
  end

  def update_confirmed_terms_version
    @shopkeeper.confirmed_terms_version = TermsVersion.current_version
    @shopkeeper.save!(validate: false)
    render json: {status: 200}, status: :ok
  end

  private

  def set_shopkeeper
    @shopkeeper = current_shopkeeper
  end
end
