class Api::V1::Shopkeeper::ItemTagsController < Api::V1::Shopkeeper::BaseController
  before_action :set_shop, only: %i[index create]
  before_action :set_item_tag, only: %i[show update destroy complete idle]

  def index
    authorize ItemTag

    @pagy, @item_tags = pagy(
      @shop.item_tags.order(:position, :name).includes(:shop),
      limit: params[:page].present? ? Pagy::OPTIONS[:limit] : 1000
    )

    options = {}
    options[:include] = [:shop]
    options[:meta] = pagy_meta(@pagy)
    render json: ItemTagSerializer.new(@item_tags, options).serializable_hash
  end

  def show
    authorize @item_tag

    render json: ItemTagSerializer.new(@item_tag).serializable_hash
  end

  def create
    item_tag = @shop.item_tags.build(item_tag_params.merge(created_by: current_shopkeeper))
    authorize item_tag

    if item_tag.save
      render json: ItemTagSerializer.new(item_tag).serializable_hash, status: :created
    else
      render_validation_error(item_tag)
    end
  end

  def update
    authorize @item_tag

    if @item_tag.update(item_tag_params)
      render json: ItemTagSerializer.new(@item_tag).serializable_hash
    else
      render_validation_error(@item_tag)
    end
  end

  def destroy
    authorize @item_tag

    @item_tag.destroy
    render json: {status: 200}, status: :ok
  end

  def complete
    authorize @item_tag

    @item_tag.complete_tag!(current_shopkeeper)

    options = {}
    options[:include] = [:shop]
    render json: ItemTagSerializer.new(@item_tag, options).serializable_hash
  end

  def idle
    authorize @item_tag

    @item_tag.reset!

    render json: ItemTagSerializer.new(@item_tag).serializable_hash
  end

  private

  def set_shop
    @shop = current_shopkeeper.shops.find(params[:shop_id])
  end

  def set_item_tag
    @item_tag = current_shopkeeper.item_tags.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error(code: 404, message: I18n.t("api.shopkeeper.item_tags.not_found"), status: :not_found)
  end

  def item_tag_params
    params.require(:item_tag).permit(:name, :description, :position, :state)
  end
end
