require "csv"

namespace :import do
  desc "Import items from Airtable CSV export"
  task airtable: :environment do
    file = ENV["FILE"]
    abort "Usage: rake import:airtable FILE=path/to/export.csv" unless file && File.exist?(file)

    puts "Importing from #{file}..."
    count = 0
    errors = 0

    CSV.foreach(file, headers: true) do |row|
      begin
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
          acquisition_cost: row["Acquisition cost"]&.gsub(/[$,]/, "")&.to_f,
          comp_price: row["Comp Price"]&.gsub(/[$,]/, "")&.to_f,
          comp_url: row["Comp url"],
          retail_price: row["Retail Price"]&.gsub(/[$,]/, "")&.to_f,
          retail_url: row["Retail url"],
          status: status,
          listed_with_vendoo: row["Listed with Vendoo"]&.downcase == "true",
          tags: row["Tags"],
          image_url: row["Image URL"]
        )

        item.save!

        # Create listings from platform price columns
        create_listing_from_price(item, "Depop", row["$ Price on Depop/Vinted/Shopify"])
        create_listing_from_price(item, "Vinted", row["$ Price on Depop/Vinted/Shopify"])
        create_listing_from_price(item, "Shopify", row["$ Price on Depop/Vinted/Shopify"])
        create_listing_from_price(item, "Poshmark", row["$ Price on Poshmark/Grailed/Mercari"])
        create_listing_from_price(item, "Grailed", row["$ Price on Poshmark/Grailed/Mercari"])
        create_listing_from_price(item, "Mercari", row["$ Price on Poshmark/Grailed/Mercari"])
        create_listing_from_price(item, "Ebay", row["$ Price on Ebay"])

        # Create sale if sold
        if row["Sold Price"].present? && row["Sold Date"].present?
          sold_platform = row["Sold Platform"].present? ? Platform.find_by(name: row["Sold Platform"].strip) : nil
          if sold_platform
            Sale.find_or_create_by!(item: item) do |sale|
              sale.platform = sold_platform
              sale.sold_price = row["Sold Price"].gsub(/[$,]/, "").to_f
              sale.revenue_received = row["Revenue Recieved"]&.gsub(/[$,]/, "")&.to_f
              sale.sold_on = Date.parse(row["Sold Date"])
            end
          end
        end

        count += 1
        print "." if count % 10 == 0
      rescue => e
        errors += 1
        puts "\nError on row #{count + errors}: #{e.message}"
      end
    end

    puts "\nDone! Imported #{count} items with #{errors} errors."
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
