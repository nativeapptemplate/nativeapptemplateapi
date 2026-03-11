module ApplicationCable
  class Channel < ActionCable::Channel::Base
    # All current channels are public (Turbo::StreamsChannel for display pages).
    # If an authenticated channel is added in the future, reject unauthorized
    # connections in that channel's #subscribed method:
    #
    #   def subscribed
    #     reject unless connection.current_shopkeeper
    #   end
  end
end
