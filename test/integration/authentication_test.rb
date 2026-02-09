require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:admin)
  end

  test "unauthenticated user is redirected to login" do
    get root_path
    assert_redirected_to new_session_path
  end

  test "login with valid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "password" }
    assert_redirected_to root_path
    follow_redirect!
    assert_response :success
  end

  test "login with invalid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "wrong" }
    assert_response :unprocessable_entity
  end

  test "logout clears session" do
    login_as @user

    delete session_path
    assert_redirected_to new_session_path

    get root_path
    assert_redirected_to new_session_path
  end

  test "login page is accessible without authentication" do
    get new_session_path
    assert_response :success
  end

  test "health check is accessible without authentication" do
    get rails_health_check_path
    assert_response :success
  end

  test "authenticated user can access dashboard" do
    login_as @user
    get root_path
    assert_response :success
  end
end
