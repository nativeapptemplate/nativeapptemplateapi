class Api::V1::Shopkeeper::Account::PasswordsController < Api::V1::Shopkeeper::BaseController
  def update
    authorize :password

    if current_shopkeeper.update_with_password(password_params)
      render json: {status: 200}, status: :ok
    else
      render_validation_error(current_shopkeeper)
    end
  end

  private

  def password_params
    params.require(:shopkeeper).permit(:current_password, :password, :password_confirmation)
  end
end
