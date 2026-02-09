class ListingsController < ApplicationController
  before_action :set_item
  before_action :set_listing, only: [ :edit, :update, :destroy, :delist ]

  def new
    @listing = @item.listings.build
    @platforms = Platform.active.where.not(id: @item.listings.pluck(:platform_id))
  end

  def create
    @listing = @item.listings.build(listing_params)
    if @listing.save
      @item.update(status: :listed) if @item.drafted?
      redirect_to @item, notice: "Listed on #{@listing.platform.name}."
    else
      @platforms = Platform.active.where.not(id: @item.listings.pluck(:platform_id))
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @platforms = Platform.active
  end

  def update
    if @listing.update(listing_params)
      redirect_to @item, notice: "Listing updated."
    else
      @platforms = Platform.active
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @listing.destroy
    redirect_to @item, notice: "Listing removed."
  end

  def delist
    @listing.delist!
    redirect_to @item, notice: "Delisted from #{@listing.platform.name}."
  end

  private

  def set_item
    @item = Item.find(params[:item_id])
  end

  def set_listing
    @listing = @item.listings.find(params[:id])
  end

  def listing_params
    params.require(:listing).permit(:platform_id, :asking_price, :status, :external_id, :external_url, :platform_notes)
  end
end
