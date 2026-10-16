# For devise_token_auth endpoints whose create action emails the address in
# params[:email] (password reset, confirmation resend). The per-address limit
# stops a stranger's inbox from being flooded from many IPs.
module ThrottleMailRequests
  extend ActiveSupport::Concern

  RENDER_MAIL_THROTTLED = -> {
    render json: {code: 429, error_message: I18n.t("errors.messages.too_many_requests")},
      status: :too_many_requests
  }

  included do
    rate_limit to: 5, within: 1.minute, only: :create,
      name: "mails/ip",
      with: RENDER_MAIL_THROTTLED

    rate_limit to: 3, within: 1.hour, only: :create,
      name: "mails/email",
      by: -> { params[:email].to_s.downcase.gsub(/\s+/, "") },
      if: -> { params[:email].present? },
      with: RENDER_MAIL_THROTTLED
  end
end
