# https://github.com/mperham/sidekiq/wiki/Monitoring#restful-authentication-or-sorcery

class AdminConstraint
  def matches?(request)
    return false unless request.session[:admin_user_id]
    AdminUser.exists?(id: request.session[:admin_user_id])
  end
end
