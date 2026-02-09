require "csv"

class CsvImportService
  def initialize(csv_import, file_path)
    @csv_import = csv_import
    @file_path = file_path
  end

  def call
    @csv_import.processing!
    count = 0
    errors = []

    CSV.foreach(@file_path, headers: true) do |row|
      begin
        import_row(row)
        count += 1
      rescue => e
        errors << "Row #{count + errors.size + 1}: #{e.message}"
      end
    end

    @csv_import.update!(
      records_count: count,
      error_log: errors.any? ? errors.join("\n") : nil,
      status: errors.any? && count == 0 ? :failed : :completed
    )
  rescue => e
    @csv_import.update!(status: :failed, error_log: "Import failed: #{e.message}")
  end

  private

  def import_row(row)
    brand = row["Brand"].present? ? Brand.find_or_create_by!(name: row["Brand"].strip) : nil
    source = row["Source"].present? ? Source.find_or_create_by!(name: row["Source"].strip) : nil
    category = row["Category"].present? ? Category.find_or_create_by!(name: row["Category"].strip) : nil
    subcategory = if row["Subcategory"].present? && category
                    category.subcategories.find_or_create_by!(name: row["Subcategory"].strip)
                  end

    status = case row["Status"]&.downcase
             when "drafted", "draft" then :drafted
             when "listed", "active" then :listed
             when "sold" then :sold
             when "archived" then :archived
             when "donated" then :donated
             else :drafted
             end

    item = Item.find_or_initialize_by(sku: row["SKU"]&.strip)
    item.assign_attributes(
      csv_import: @csv_import,
      general_title: row["General title"],
      shopify_title: row["Shopify title"],
      description: row["Description"],
      chatgpt_description: row["ChatGPT Description"],
      brand: brand,
      category: category,
      subcategory: subcategory,
      size: row["Size"],
      product_model: row["Model"],
      colors: row["Colors"],
      materials: row["Materials"],
      body_fit: row["Body Fit"],
      fit: row["Fit"],
      item_type: row["Item type"],
      product_type: row["Product type"],
      occasion: row["Occasion"],
      weight: row["Weight"]&.to_f,
      imperfections: row["Imperfections"],
      notes: row["Notes"],
      source: source,
      acquisition_cost: parse_currency(row["Acquisition cost"]),
      comp_price: parse_currency(row["Comp Price"]),
      comp_url: row["Comp url"],
      retail_price: parse_currency(row["Retail Price"]),
      retail_url: row["Retail url"],
      status: status,
      listed_with_vendoo: row["Listed with Vendoo"]&.downcase == "true",
      tags: row["Tags"],
      image_url: row["Image URL"]
    )
    item.save!

    create_listing_from_price(item, "Depop", row["$ Price on Depop/Vinted/Shopify"])
    create_listing_from_price(item, "Vinted", row["$ Price on Depop/Vinted/Shopify"])
    create_listing_from_price(item, "Shopify", row["$ Price on Depop/Vinted/Shopify"])
    create_listing_from_price(item, "Poshmark", row["$ Price on Poshmark/Grailed/Mercari"])
    create_listing_from_price(item, "Grailed", row["$ Price on Poshmark/Grailed/Mercari"])
    create_listing_from_price(item, "Mercari", row["$ Price on Poshmark/Grailed/Mercari"])
    create_listing_from_price(item, "Ebay", row["$ Price on Ebay"])

    if row["Sold Price"].present? && row["Sold Date"].present?
      sold_price = row["Sold Price"].gsub(/[$,]/, "").to_f
      sold_platform = row["Sold Platform"].present? ? Platform.find_by(name: row["Sold Platform"].strip) : nil
      if sold_platform && sold_price > 0
        Sale.find_or_create_by!(item: item) do |sale|
          sale.platform = sold_platform
          sale.sold_price = sold_price
          sale.revenue_received = row["Revenue Recieved"]&.gsub(/[$,]/, "")&.to_f
          sale.sold_on = Date.parse(row["Sold Date"])
        end
      end
    end
  end

  def create_listing_from_price(item, platform_name, price_str)
    return if price_str.blank?
    price = price_str.gsub(/[$,]/, "").to_f
    return if price <= 0

    platform = Platform.find_by(name: platform_name)
    return unless platform

    listing_status = item.sold? ? :delisted : :active
    item.listings.find_or_create_by!(platform: platform) do |listing|
      listing.asking_price = price
      listing.status = listing_status
    end
  rescue ActiveRecord::RecordInvalid
    # Skip duplicate listings
  end

  def parse_currency(value)
    return nil if value.blank?
    value.gsub(/[$,]/, "").to_f
  end
end
