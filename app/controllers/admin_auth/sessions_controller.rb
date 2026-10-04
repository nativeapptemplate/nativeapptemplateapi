class AdminAuth::SessionsController < ActionController::Base
  RENDER_LOGIN_THROTTLED = -> {
    flash.now[:alert] = I18n.t("errors.messages.too_many_logins")
    render :new, status: :too_many_requests
  }
  private_constant :RENDER_LOGIN_THROTTLED

  rate_limit to: 5, within: 1.minute, only: :create,
    name: "admin_logins/ip",
    with: RENDER_LOGIN_THROTTLED

  rate_limit to: 5, within: 1.minute, only: :create,
    name: "admin_logins/email",
    by: -> { params[:email].to_s.downcase.strip },
    if: -> { params[:email].present? },
    with: RENDER_LOGIN_THROTTLED

  def new
  end

  def create
    admin_user = AdminUser.find_by(email: params[:email])
    if admin_user.present? && admin_user.authenticate(params[:password])
      # A fresh session id, so one planted before sign-in can't be reused
      reset_session
      session[:admin_user_id] = admin_user.id
      redirect_to madmin_root_path, notice: "Logged in successfully"
    else
      flash.now[:alert] = "Invalid email or password"
      render :new
    end
  end

  def destroy
    reset_session
    redirect_to new_admin_session_path, notice: "Logged Out"
  end
end
