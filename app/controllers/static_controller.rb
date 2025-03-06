class StaticController < NonApiApplicationController
  layout "minimal"

  def index
  end

  def scan
    return if params[:type].blank?
    return if params[:item_tag_id].blank?

    return unless params[:type] == "server"

    redirect_to(ConfigSettings.site.url, allow_other_host: true)
  end

  def scan_customer
    return if params[:type].blank?
    return if params[:item_tag_id].blank?

    return unless params[:type] == "customer"

    item_tag = ItemTag.find_by(id: params[:item_tag_id])
    return if item_tag.blank?

    item_tag.scan_tag!

    shop = item_tag.shop
    redirect_to display_shop_path(shop, params: {type: params[:type], item_tag_id: params[:item_tag_id]})
  end
end
