class BrandsController < ApplicationController
  def index
    @brands = Brand.order(:name)
  end

  def create
    @brand = Brand.new(name: params[:brand][:name])
    if @brand.save
      redirect_back fallback_location: brands_path, notice: "Brand created."
    else
      redirect_back fallback_location: brands_path, alert: @brand.errors.full_messages.join(", ")
    end
  end
end
