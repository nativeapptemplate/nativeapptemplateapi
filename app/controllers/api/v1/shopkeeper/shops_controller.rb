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

    shops = current_shopkeeper.shops.order(name: :asc)
    render json: ShopSerializer.new(shops, options).serializable_hash
  end

  def show
    authorize @shop

    render json: ShopSerializer.new(@shop).serializable_hash
  end

  def create
    shop = Shop.new(shop_params_create.merge(created_by: current_shopkeeper))
    authorize shop

    if shop.save
      render json: ShopSerializer.new(shop).serializable_hash, status: :created
    else
      render json: {code: 422, error_message: shop.errors.full_messages.to_sentence}, status: :unprocessable_entity
    end
  end

  def update
    authorize @shop

    if @shop.update(shop_params_update)
      render json: ShopSerializer.new(@shop).serializable_hash
    else
      render json: {code: 422, error_message: @shop.errors.full_messages.to_sentence}, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @shop

    @shop.destroy
    render json: {status: 200}, status: :ok
  end

  private

  def set_shop
    @shop = current_shopkeeper.shops.find(params[:id])
  end

  def shop_params_create
    params
      .require(:shop).permit(
        :name,
        :description,
        :time_zone
      )
  end

  def shop_params_update
    params
      .require(:shop).permit(
        :name,
        :description,
        :time_zone
      )
  end
end
