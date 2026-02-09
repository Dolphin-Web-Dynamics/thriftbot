class CategoriesController < ApplicationController
  def index
    @categories = Category.includes(:subcategories).order(:name)
  end

  def create
    @category = Category.new(name: params[:category][:name])
    if @category.save
      redirect_back fallback_location: categories_path, notice: "Category created."
    else
      redirect_back fallback_location: categories_path, alert: @category.errors.full_messages.join(", ")
    end
  end
end
