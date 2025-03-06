class Display::ShopsController < Display::BaseController
  layout "display"
  before_action :set_shop, only: %i[show]

  def show
  end

  private

  def set_shop
    @shop = Shop.find(params[:id])
  end
end
