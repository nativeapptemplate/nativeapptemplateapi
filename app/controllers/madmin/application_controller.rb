module Madmin
  class ApplicationController < Madmin::BaseController
    before_action :authenticate_admin_user
    around_action :without_tenant

    # Check the admin still exists, like AdminConstraint does for /madmin/jobs,
    # so deleting an admin ends their access
    def authenticate_admin_user
      return if session[:admin_user_id] && AdminUser.exists?(id: session[:admin_user_id])

      reset_session
      redirect_to "/", alert: "Not authorized."
    end

    def without_tenant
      ActsAsTenant.without_tenant do
        yield
      end
    end

    # Authenticate with Clearance
    # include Clearance::Controller
    # before_action :require_login

    # Authenticate with Devise
    # before_action :authenticate_user!

    # Authenticate with Basic Auth
    # http_basic_authenticate_with(name: Rails.application.credentials.admin_username, password: Rails.application.credentials.admin_password)
  end
end
