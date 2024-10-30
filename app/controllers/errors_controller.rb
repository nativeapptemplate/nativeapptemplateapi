class ErrorsController < NonApiApplicationController
  def not_found
    if request.content_type&.include?("application/json")
      render json: {code: 404, error_message: "Not found."}, status: 404
    else
      render status: 404
    end
  end

  def internal_server_error
    if request.content_type&.include?("application/json")
      render json: {code: 500, error_message: "Internal server error."}, status: 500
    else
      render status: 500
    end
  end
end
