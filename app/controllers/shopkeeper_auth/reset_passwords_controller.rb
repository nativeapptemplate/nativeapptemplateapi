class ShopkeeperAuth::ResetPasswordsController < NonApiApplicationController
  before_action :set_minimum_password_length, only: %i[edit]
  layout "minimal"

  def new
  end

  def show
  end

  def edit
  end

  private

  def set_minimum_password_length
    @minimum_password_length = ConfigSettings.minimum_password_length
  end
end
