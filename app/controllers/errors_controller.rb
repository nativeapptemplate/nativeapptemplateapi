class ErrorsController < NonApiApplicationController
  # AccountMiddleware has already moved any /<account uuid> prefix into script_name
  API_PATH = %r{\A/api/}

  def not_found
    render_error(404, t("not_found"))
  end

  def internal_server_error
    render_error(500, t("internal_server_error"))
  end

  private

  def render_error(status, message)
    if request.content_type&.include?("application/json") || api_request?
      render json: {code: status, error_message: message}, status: status
    else
      render status: status
    end
  end

  # The exceptions app sees /404 or /500; the failed request's path is kept here
  def api_request?
    request.env["action_dispatch.original_path"].to_s.match?(API_PATH)
  end
end
