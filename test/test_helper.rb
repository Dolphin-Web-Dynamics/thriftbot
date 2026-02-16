ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Set tenant for model tests
    def set_tenant(user)
      ActsAsTenant.current_tenant = user
    end

    teardown do
      ActsAsTenant.current_tenant = nil
    end
  end
end

class ActionDispatch::IntegrationTest
  def login_as(user)
    post session_path, params: { email_address: user.email_address, password: "password" }
    follow_redirect! # root_path -> pages#home
    follow_redirect! # pages#home -> dashboard_path (for logged-in users)
  end
end
