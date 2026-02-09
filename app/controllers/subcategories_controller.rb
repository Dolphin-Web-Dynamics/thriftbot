class SubcategoriesController < ApplicationController
  def create
    @category = Category.find(params[:category_id])
    @subcategory = @category.subcategories.build(name: params[:subcategory][:name])
    if @subcategory.save
      redirect_back fallback_location: categories_path, notice: "Subcategory created."
    else
      redirect_back fallback_location: categories_path, alert: @subcategory.errors.full_messages.join(", ")
    end
  end
end
