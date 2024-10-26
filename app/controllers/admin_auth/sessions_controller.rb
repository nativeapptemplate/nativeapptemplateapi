class AdminAuth::SessionsController < ActionController::Base
  def new
  end

  def create
    admin_user = AdminUser.find_by(email: params[:email])
    if admin_user.present? && admin_user.authenticate(params[:password])
      session[:admin_user_id] = admin_user.id
      redirect_to madmin_root_path, notice: "Logged in successfully"
    else
      flash.now[:alert] = "Invalid email or password"
      render :new
    end
  end

  def destroy
    # deletes admin_user session
    session[:admin_user_id] = nil
    redirect_to new_admin_session_path, notice: "Logged Out"
  end
end
