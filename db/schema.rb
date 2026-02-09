# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_08_232815) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "ai_generations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "field_name"
    t.integer "item_id", null: false
    t.string "model_used"
    t.text "prompt_used"
    t.text "result"
    t.integer "tokens_used"
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_ai_generations_on_item_id"
  end

  create_table "brands", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_brands_on_name", unique: true
  end

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
  end

  create_table "csv_imports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error_log"
    t.string "filename", null: false
    t.integer "records_count", default: 0
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
  end

  create_table "items", force: :cascade do |t|
    t.date "acquired_on"
    t.decimal "acquisition_cost", precision: 8, scale: 2
    t.string "body_fit"
    t.integer "brand_id"
    t.string "canva_url"
    t.integer "category_id"
    t.text "chatgpt_description"
    t.string "colors"
    t.decimal "comp_price", precision: 8, scale: 2
    t.string "comp_url"
    t.integer "condition", default: 0
    t.datetime "created_at", null: false
    t.integer "csv_import_id"
    t.text "description"
    t.string "fit"
    t.string "general_title"
    t.string "image_url"
    t.text "imperfections"
    t.string "item_type"
    t.boolean "listed_with_vendoo", default: false, null: false
    t.string "materials"
    t.text "notes"
    t.string "occasion"
    t.string "picture_label_url"
    t.string "product_model"
    t.string "product_type"
    t.decimal "retail_price", precision: 8, scale: 2
    t.string "retail_url"
    t.string "shopify_title"
    t.string "size"
    t.string "sku", null: false
    t.integer "source_id"
    t.integer "status", default: 0, null: false
    t.datetime "status_changed_at"
    t.integer "subcategory_id"
    t.string "tags"
    t.integer "target_gender"
    t.text "unified_description"
    t.datetime "updated_at", null: false
    t.decimal "weight", precision: 8, scale: 2
    t.index ["brand_id"], name: "index_items_on_brand_id"
    t.index ["category_id"], name: "index_items_on_category_id"
    t.index ["csv_import_id"], name: "index_items_on_csv_import_id"
    t.index ["item_type"], name: "index_items_on_item_type"
    t.index ["sku"], name: "index_items_on_sku", unique: true
    t.index ["source_id"], name: "index_items_on_source_id"
    t.index ["status"], name: "index_items_on_status"
    t.index ["subcategory_id"], name: "index_items_on_subcategory_id"
  end

  create_table "listings", force: :cascade do |t|
    t.decimal "asking_price", precision: 8, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "delisted_at"
    t.string "external_id"
    t.string "external_url"
    t.integer "item_id", null: false
    t.datetime "listed_at"
    t.integer "platform_id", null: false
    t.text "platform_notes"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["item_id", "platform_id"], name: "index_listings_on_item_id_and_platform_id", unique: true
    t.index ["item_id"], name: "index_listings_on_item_id"
    t.index ["platform_id"], name: "index_listings_on_platform_id"
  end

  create_table "platforms", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.decimal "fee_percentage", precision: 5, scale: 2
    t.string "name", null: false
    t.string "pricing_tier"
    t.datetime "updated_at", null: false
    t.string "url_template"
    t.index ["name"], name: "index_platforms_on_name", unique: true
  end

  create_table "sales", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "item_id", null: false
    t.integer "listing_id"
    t.text "notes"
    t.decimal "platform_fees", precision: 8, scale: 2
    t.integer "platform_id", null: false
    t.decimal "revenue_received", precision: 8, scale: 2
    t.decimal "shipping_cost", precision: 8, scale: 2
    t.date "sold_on", null: false
    t.decimal "sold_price", precision: 8, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_sales_on_item_id"
    t.index ["listing_id"], name: "index_sales_on_listing_id"
    t.index ["platform_id"], name: "index_sales_on_platform_id"
    t.index ["sold_on"], name: "index_sales_on_sold_on"
  end

  create_table "sources", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "source_type"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_sources_on_name", unique: true
  end

  create_table "subcategories", force: :cascade do |t|
    t.integer "category_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id", "name"], name: "index_subcategories_on_category_id_and_name", unique: true
    t.index ["category_id"], name: "index_subcategories_on_category_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "ai_generations", "items"
  add_foreign_key "items", "brands"
  add_foreign_key "items", "categories"
  add_foreign_key "items", "csv_imports"
  add_foreign_key "items", "sources"
  add_foreign_key "items", "subcategories"
  add_foreign_key "listings", "items"
  add_foreign_key "listings", "platforms"
  add_foreign_key "sales", "items"
  add_foreign_key "sales", "listings"
  add_foreign_key "sales", "platforms"
  add_foreign_key "subcategories", "categories"
end
