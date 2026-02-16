require "test_helper"

class OmniauthCallbacksControllerTest < ActionDispatch::IntegrationTest
  setup do
    OmniAuth.config.test_mode = true
  end

  teardown do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.test_mode = false
  end

  test "creates new user from Google OAuth" do
    mock_google_auth(email: "newuser@gmail.com", uid: "999888777")

    assert_difference "User.count", 1 do
      post "/auth/google_oauth2/callback"
    end

    user = User.find_by(email_address: "newuser@gmail.com")
    assert_equal "google_oauth2", user.provider
    assert_equal "999888777", user.uid
    assert_redirected_to root_path
  end

  test "links Google to existing email/password user" do
    existing_user = users(:admin)

    mock_google_auth(email: existing_user.email_address, uid: "111222333")

    assert_no_difference "User.count" do
      post "/auth/google_oauth2/callback"
    end

    existing_user.reload
    assert_equal "google_oauth2", existing_user.provider
    assert_equal "111222333", existing_user.uid
    assert_redirected_to root_path
  end

  test "signs in returning Google user" do
    google_user = users(:google_user)

    mock_google_auth(email: google_user.email_address, uid: google_user.uid)

    assert_no_difference "User.count" do
      post "/auth/google_oauth2/callback"
    end

    assert_redirected_to root_path
  end

  test "handles OAuth failure" do
    get "/auth/failure", params: { message: "access_denied" }

    assert_redirected_to new_session_path
    assert_equal "Authentication failed: Access denied", flash[:alert]
  end

  private

  def mock_google_auth(email:, uid:, email_verified: true)
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: uid,
      info: { email: email, name: "Test User" },
      extra: { id_info: { email_verified: email_verified }, raw_info: { email_verified: email_verified } }
    )

    Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:google_oauth2]
  end
end
