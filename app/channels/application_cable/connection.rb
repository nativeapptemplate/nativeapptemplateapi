module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_shopkeeper, :current_account

    def connect
      self.current_shopkeeper = find_shopkeeper
      self.current_account = find_account
    end

    private

    def find_shopkeeper
      env["warden"]&.user(:shopkeeper)
    end

    # Extract the account UUID from the WebSocket upgrade request path,
    # matching how AccountMiddleware sets the current account for HTTP
    # requests. Display page URLs (display/shops/...) don't include an
    # account UUID, so this returns nil for public connections.
    def find_account
      _, account_id, = request.path.split("/", 3)
      Account.find_by(id: account_id) if AccountMiddleware::UUID_MATCHER.match?(account_id)
    end
  end
end
