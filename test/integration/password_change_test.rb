require "test_helper"

class PasswordChangeTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:admin)
    login_as @user
  end

  test "can access change password page" do
    get edit_password_path
    assert_response :success
    assert_select "h1", "Change Password"
  end

  test "change password with valid current password" do
    patch password_path, params: {
      current_password: "password",
      password: "newpassword123",
      password_confirmation: "newpassword123"
    }
    assert_redirected_to root_path
    follow_redirect!
    assert_select ".bg-green-50", /Password updated successfully/

    # Verify old password no longer works
    delete session_path
    post session_path, params: { email_address: @user.email_address, password: "password" }
    assert_response :unprocessable_entity

    # Verify new password works
    post session_path, params: { email_address: @user.email_address, password: "newpassword123" }
    assert_redirected_to root_path
  end

  test "reject change with wrong current password" do
    patch password_path, params: {
      current_password: "wrongpassword",
      password: "newpassword123",
      password_confirmation: "newpassword123"
    }
    assert_response :unprocessable_entity
    assert_select ".bg-red-50", /Current password is incorrect/
  end

  test "reject change when confirmation does not match" do
    patch password_path, params: {
      current_password: "password",
      password: "newpassword123",
      password_confirmation: "mismatch"
    }
    assert_response :unprocessable_entity
  end

  test "unauthenticated user cannot access change password page" do
    delete session_path
    get edit_password_path
    assert_redirected_to new_session_path
  end
end
