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

    # Display pages are public — anonymous connections are allowed.
    # Shopkeeper auth is header-based (devise_token_auth), so most
    # WebSocket connections will be anonymous. If an authenticated-only
    # channel is added in the future, reject in that channel's #subscribed.
    def find_account
      current_shopkeeper&.accounts&.order(created_at: :asc)&.first
    end
  end
end
