require "test_helper"

class Api::V1::ItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @item = items(:one)
    @token = "test_admin_password"
    @prev_admin_password = ENV["ADMIN_PASSWORD"]
    ENV["ADMIN_PASSWORD"] = @token
  end

  teardown do
    ENV["ADMIN_PASSWORD"] = @prev_admin_password
  end

  def auth_headers
    { "Authorization" => "Bearer #{@token}" }
  end

  # Authentication

  test "returns unauthorized without token" do
    get api_v1_items_path
    assert_response :unauthorized
  end

  test "returns unauthorized with wrong token" do
    get api_v1_items_path, headers: { "Authorization" => "Bearer wrong" }
    assert_response :unauthorized
  end

  # GET /api/v1/items

  test "index returns all items" do
    get api_v1_items_path, headers: auth_headers
    assert_response :success

    json = JSON.parse(response.body)
    assert json["items"].is_a?(Array)
    assert json["items"].length >= 2
  end

  test "index with vendoo_ready scope filters unlisted items" do
    @item.update!(listed_with_vendoo: true)

    get api_v1_items_path, params: { scope: "vendoo_ready" }, headers: auth_headers
    assert_response :success

    json = JSON.parse(response.body)
    skus = json["items"].map { |i| i["sku"] }
    assert_not_includes skus, @item.sku
  end

  test "index returns correct item fields" do
    get api_v1_items_path, headers: auth_headers
    assert_response :success

    json = JSON.parse(response.body)
    item_json = json["items"].find { |i| i["sku"] == "SKU-001" }

    assert_equal @item.id, item_json["id"]
    assert_equal "SKU-001", item_json["sku"]
    assert_equal "Nike T-Shirt", item_json["title"]
    assert_equal "A nice t-shirt", item_json["description"]
    assert_equal "Nike", item_json["brand"]
    assert_equal "Black", item_json["colors"]
    assert_equal "M", item_json["size"]
    assert_equal 0.5, item_json["weight_lbs"]
    assert_equal "nike,tshirt", item_json["tags"]
    assert_equal 9.99, item_json["price"]
  end

  # GET /api/v1/items/:id

  test "show returns single item" do
    get api_v1_item_path(@item), headers: auth_headers
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal @item.id, json["item"]["id"]
    assert_equal "SKU-001", json["item"]["sku"]
  end

  test "show returns 404 for missing item" do
    get api_v1_item_path(id: 999999), headers: auth_headers
    assert_response :not_found
  end

  # PATCH /api/v1/items/:id/mark_listed

  test "mark_listed sets listed_with_vendoo to true" do
    assert_not @item.listed_with_vendoo

    patch mark_listed_api_v1_item_path(@item), headers: auth_headers
    assert_response :success

    @item.reload
    assert @item.listed_with_vendoo

    json = JSON.parse(response.body)
    assert json["item"]["listed_with_vendoo"]
  end

  test "mark_listed requires authentication" do
    patch mark_listed_api_v1_item_path(@item)
    assert_response :unauthorized
  end
end
