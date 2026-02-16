# Platforms with pricing tiers and approximate fee percentages
platforms = [
  { name: "Depop",       pricing_tier: "lower",  fee_percentage: 10.0 },
  { name: "Vinted",      pricing_tier: "lower",  fee_percentage: 0.0 },
  { name: "Shopify",     pricing_tier: "lower",  fee_percentage: 2.9 },
  { name: "Poshmark",    pricing_tier: "mid",    fee_percentage: 20.0 },
  { name: "Grailed",     pricing_tier: "mid",    fee_percentage: 9.0 },
  { name: "Mercari",     pricing_tier: "mid",    fee_percentage: 10.0 },
  { name: "Ebay",        pricing_tier: "higher", fee_percentage: 13.25 },
  { name: "Whatnot",     pricing_tier: nil,       fee_percentage: 8.0 },
  { name: "Indy Clover", pricing_tier: nil,       fee_percentage: nil },
  { name: "Uptown",      pricing_tier: nil,       fee_percentage: nil }
]

platforms.each do |attrs|
  Platform.find_or_create_by!(name: attrs[:name]) do |p|
    p.pricing_tier = attrs[:pricing_tier]
    p.fee_percentage = attrs[:fee_percentage]
  end
end
puts "Seeded #{Platform.count} platforms"

# Sources
%w[DI Ginger Closet/Gift Ross Bins].each do |name|
  Source.find_or_create_by!(name: name)
end
puts "Seeded #{Source.count} sources"

# Categories and subcategories
categories = {
  "Tops" => [ "T-Shirts", "Sweaters", "Hoodies", "Polos", "Button-Downs", "Tank Tops", "Long Sleeves" ],
  "Bottoms" => [ "Jeans", "Shorts", "Pants", "Joggers", "Sweatpants", "Cargo" ],
  "Outerwear" => [ "Jackets", "Coats", "Vests", "Windbreakers", "Puffers", "Fleece" ],
  "Footwear" => [ "Sneakers", "Boots", "Sandals", "Dress Shoes", "Slides" ],
  "Accessories" => [ "Hats", "Bags", "Belts", "Scarves", "Jewelry", "Sunglasses", "Watches" ],
  "Dresses & Skirts" => [ "Dresses", "Skirts", "Jumpsuits", "Rompers" ],
  "Activewear" => [ "Sports Tops", "Leggings", "Shorts", "Sports Bras" ],
  "Suits & Formalwear" => [ "Blazers", "Dress Pants", "Suits", "Ties" ]
}

categories.each do |cat_name, subs|
  cat = Category.find_or_create_by!(name: cat_name)
  subs.each do |sub_name|
    cat.subcategories.find_or_create_by!(name: sub_name)
  end
end
puts "Seeded #{Category.count} categories with #{Subcategory.count} subcategories"

# Admin user
admin_email = ENV.fetch("ADMIN_EMAIL", "anel@dolphinwebdynamics.com")
admin = User.find_or_initialize_by(email_address: admin_email)
if admin.new_record?
  admin.password = ENV["ADMIN_PASSWORD"] || Rails.application.credentials.admin_password || raise("Set ADMIN_PASSWORD env var or add admin_password to credentials")
  admin.save!
  puts "Seeded admin user: #{admin_email}"
else
  puts "Admin user already exists, skipping"
end
