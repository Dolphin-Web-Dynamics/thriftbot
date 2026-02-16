class ItemsController < ApplicationController
  before_action :set_item, only: [ :show, :edit, :update, :destroy, :generate_ai_content, :update_ai_content, :record_sale ]

  def index
    @q = Item.ransack(params[:q])
    @q.sorts = "created_at desc" if @q.sorts.empty?
    @items = @q.result.includes(:brand, :source, :category, :listings)
    @pagy, @items = pagy(@items, limit: 25)
    @brands_for_select = Brand.order(:name).pluck(:name, :id)
    @sources_for_select = Source.order(:name).pluck(:name, :id)
  end

  def show
    @listings = @item.listings.includes(:platform)
    @sale = @item.sale
    @platforms_for_select = Platform.active.order(:name).pluck(:name, :id)
  end

  def new
    @item = Item.new
  end

  def create
    unless current_user.can_create_items?
      redirect_to new_subscription_path, alert: "You've reached the free tier limit of #{User::FREE_TIER_ITEM_LIMIT} items. Upgrade to Pro for unlimited items."
      return
    end

    @item = Item.new(item_params)
    if @item.save
      redirect_to @item, notice: "Item created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @item.update(item_params)
      redirect_to @item, notice: "Item updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @item.destroy
    redirect_to items_path, notice: "Item deleted."
  end

  def update_ai_content
    if @item.update(ai_content_params)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("ai_content", partial: "items/ai_content", locals: { item: @item }) }
        format.html { redirect_to @item, notice: "AI content updated." }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("ai_content", partial: "items/ai_content", locals: { item: @item }) }
        format.html { redirect_to @item, alert: "Failed to update AI content." }
      end
    end
  end

  def generate_ai_content
    GenerateAiContentJob.perform_later(@item.id)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @item, notice: "AI content generation started." }
    end
  end

  def record_sale
    platform = Platform.find(params[:platform_id])
    listing = @item.listings.find_by(platform: platform)

    @sale = @item.build_sale(
      platform: platform,
      listing: listing,
      sold_price: params[:sold_price],
      revenue_received: params[:revenue_received],
      platform_fees: params[:platform_fees],
      shipping_cost: params[:shipping_cost],
      sold_on: params[:sold_on] || Date.current,
      notes: params[:sale_notes]
    )

    if @sale.save
      redirect_to @item, notice: "Sale recorded! Item marked as sold."
    else
      redirect_to @item, alert: "Could not record sale: #{@sale.errors.full_messages.join(', ')}"
    end
  end

  private

  def set_item
    @item = Item.find(params[:id])
  end

  def ai_content_params
    params.require(:item).permit(:chatgpt_description, :shopify_title, :unified_description)
  end

  def item_params
    params.require(:item).permit(
      :sku, :general_title, :shopify_title, :description,
      :chatgpt_description, :unified_description,
      :brand_id, :category_id, :subcategory_id,
      :size, :product_model, :colors, :materials,
      :body_fit, :fit, :item_type, :product_type,
      :condition, :occasion, :target_gender,
      :weight, :length, :width, :height, :imperfections, :notes,
      :source_id, :acquisition_cost, :acquired_on,
      :comp_price, :comp_url, :retail_price, :retail_url,
      :status, :listed_with_vendoo, :zip_code,
      :canva_url, :picture_label_url, :image_url, :tags,
      :front_image, :back_image,
      measurement_images: [], tag_images: [],
      imperfection_images: [], additional_images: []
    )
  end
end
