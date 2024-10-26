module Madmin
  class ApplicationController < Madmin::BaseController
    before_action :authenticate_admin_user
    around_action :without_tenant

    def authenticate_admin_user
      # TODO: Add your authentication logic here

      # For example, we could redirect if the user isn't an admin
      redirect_to "/", alert: "Not authorized." if session[:admin_user_id].nil?
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
