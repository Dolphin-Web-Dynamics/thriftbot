require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  if ENV["CUPRITE"] != "false"
    require "capybara/cuprite"

    driven_by :cuprite, screen_size: [ 1400, 900 ], options: {
      headless: true,
      process_timeout: 15,
      timeout: 15,
      browser_options: { "no-sandbox": nil }
    }
  else
    driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 900 ]
  end

  def login_as_user(user)
    visit new_session_path
    fill_in "Email address", with: user.email_address
    fill_in "Password", with: TEST_USER_PASSWORD
    click_button "Sign in"
  end
end
