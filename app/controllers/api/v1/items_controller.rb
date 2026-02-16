module Api
  module V1
    class ItemsController < BaseController
      include Rails.application.routes.url_helpers

      before_action :set_item, only: [ :show, :mark_listed ]

      # GET /api/v1/items
      # GET /api/v1/items?scope=vendoo_ready
      def index
        items = Item.includes(:brand, :category, :listings)

        if params[:scope] == "vendoo_ready"
          items = items.where(listed_with_vendoo: false).where.not(status: [ :sold, :archived, :donated ])
        end

        render json: { items: items.map { |item| serialize_item(item) } }
      end

      # GET /api/v1/items/:id
      def show
        render json: { item: serialize_item(@item) }
      end

      # PATCH /api/v1/items/:id/mark_listed
      def mark_listed
        @item.update!(listed_with_vendoo: true)
        render json: { item: { id: @item.id, listed_with_vendoo: true } }
      end

      private

      def set_item
        @item = Item.find(params[:id])
      end

      def serialize_item(item)
        listing = item.listings.max_by(&:asking_price)

        {
          id: item.id,
          sku: item.sku,
          title: item.general_title,
          description: item.unified_description.presence || item.description,
          price: listing&.asking_price&.to_f,
          cost: item.acquisition_cost&.to_f,
          brand: item.brand&.name,
          category: item.category&.name,
          condition: item.condition,
          colors: item.colors,
          size: item.size,
          weight_lbs: item.weight&.to_f,
          length: item.length&.to_f,
          width: item.width&.to_f,
          height: item.height&.to_f,
          tags: item.tags,
          notes: item.notes,
          zip_code: item.zip_code,
          image_urls: image_urls_for(item)
        }
      end

      def image_urls_for(item)
        urls = []
        urls << url_for(item.front_image) if item.front_image.attached?
        urls << url_for(item.back_image) if item.back_image.attached?
        item.additional_images.each { |img| urls << url_for(img) } if item.additional_images.attached?
        item.measurement_images.each { |img| urls << url_for(img) } if item.measurement_images.attached?
        item.tag_images.each { |img| urls << url_for(img) } if item.tag_images.attached?
        urls
      end
    end
  end
end
