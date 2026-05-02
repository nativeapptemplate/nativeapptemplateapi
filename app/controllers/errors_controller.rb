class ErrorsController < NonApiApplicationController
  def not_found
    render_error(404, "Not found.")
  end

  def internal_server_error
    render_error(500, "Internal server error.")
  end

  private

  def render_error(status, message)
    if request.content_type&.include?("application/json")
      render json: {code: status, error_message: message}, status: status
    else
      render status: status
    end
  end
end
