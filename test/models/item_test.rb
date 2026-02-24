require "test_helper"

class ItemTest < ActiveSupport::TestCase
  setup do
    @item = items(:one)
  end

  test "valid item" do
    assert @item.valid?
  end

  test "rejects invalid content type for front_image" do
    @item.front_image.attach(
      io: StringIO.new("not a real pdf"),
      filename: "doc.pdf",
      content_type: "application/pdf"
    )
    assert_not @item.valid?
    assert @item.errors[:front_image].any?
  end

  test "rejects oversized front_image" do
    @item.front_image.attach(
      io: StringIO.new("x" * (11 * 1024 * 1024)),
      filename: "huge.jpg",
      content_type: "image/jpeg"
    )
    assert_not @item.valid?
    assert @item.errors[:front_image].any?
  end

  test "accepts valid jpeg front_image" do
    @item.front_image.attach(
      io: StringIO.new("fake image data"),
      filename: "photo.jpg",
      content_type: "image/jpeg"
    )
    assert @item.valid?
  end

  test "accepts valid webp front_image" do
    @item.front_image.attach(
      io: StringIO.new("fake image data"),
      filename: "photo.webp",
      content_type: "image/webp"
    )
    assert @item.valid?
  end

  test "accepts valid heic front_image" do
    @item.front_image.attach(
      io: StringIO.new("fake image data"),
      filename: "photo.heic",
      content_type: "image/heic"
    )
    assert @item.valid?
  end

  test "rejects invalid content type for back_image" do
    @item.back_image.attach(
      io: StringIO.new("not a real gif"),
      filename: "anim.gif",
      content_type: "image/gif"
    )
    assert_not @item.valid?
    assert @item.errors[:back_image].any?
  end

  test "rejects invalid content type for measurement_images" do
    @item.measurement_images.attach(
      io: StringIO.new("not a video"),
      filename: "clip.mp4",
      content_type: "video/mp4"
    )
    assert_not @item.valid?
    assert @item.errors[:measurement_images].any?
  end

  test "rejects oversized additional_images" do
    @item.additional_images.attach(
      io: StringIO.new("x" * (11 * 1024 * 1024)),
      filename: "huge.png",
      content_type: "image/png"
    )
    assert_not @item.valid?
    assert @item.errors[:additional_images].any?
  end
end
