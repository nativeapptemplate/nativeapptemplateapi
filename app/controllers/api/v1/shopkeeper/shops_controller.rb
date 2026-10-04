class Api::V1::Shopkeeper::ShopsController < Api::V1::Shopkeeper::BaseController
  before_action :set_shop, only: %i[show update destroy]

  def index
    authorize Shop

    created_shops_count = 0
    ActsAsTenant.without_tenant do
      created_shops_count = current_shopkeeper.created_shops.size
    end

    options = {}
    options[:meta] = {
      limit_count: ConfigSettings.shop.limit_count,
      created_shops_count: created_shops_count
    }

    shops = current_shopkeeper.shops.order(name: :asc).includes(:item_tags)
    render json: ShopSerializer.new(shops, options).serializable_hash
  end

  def show
    authorize @shop

    render json: ShopSerializer.new(@shop).serializable_hash
  end

  def create
    shop = Shop.new(shop_params.merge(created_by: current_shopkeeper))
    authorize shop

    if shop.save
      render json: ShopSerializer.new(shop).serializable_hash, status: :created
    else
      render_validation_error(shop)
    end
  end

  def update
    authorize @shop

    if @shop.update(shop_params)
      render json: ShopSerializer.new(@shop).serializable_hash
    else
      render_validation_error(@shop)
    end
  end

  def destroy
    authorize @shop

    @shop.destroy!
    render json: {status: 200}, status: :ok
  end

  private

  def set_shop
    @shop = current_shopkeeper.shops.find(params[:id])
  end

  def shop_params
    params.require(:shop).permit(:name, :description, :time_zone)
  end
end
