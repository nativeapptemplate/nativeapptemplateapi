class Display::ItemTagsController < Display::BaseController
  before_action :set_shop

  def completings
    items_count = 9

    @pagy, @completed_item_tags = pagy(
      @shop.item_tags.completed.sorted,
      limit: items_count
    )

    @type = params[:type]
    @item_tag_id = params[:item_tag_id]

    render layout: false
  end

  private

  def set_shop
    @shop = Shop.find(params[:shop_id])
  end
end
