class SessionsController < ApplicationController
  skip_before_action :require_login, only: %i[new create]

  rate_limit to: 10, within: 3.minutes, only: :create

  def new
  end

  def create
    ensure_admin_user_exists if params[:email_address]&.strip&.downcase == ApplicationController::ADMIN_EMAIL

    user = User.authenticate_by(email_address: params[:email_address], password: params[:password])

    if user
      session[:user_id] = user.id
      redirect_to root_path, notice: "Logged in successfully."
    else
      flash.now[:alert] = "Invalid email or password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to new_session_path, notice: "Logged out."
  end

  private

  def ensure_admin_user_exists
    return if User.exists?(email_address: ApplicationController::ADMIN_EMAIL)

    admin_password = ENV["ADMIN_PASSWORD"] || Rails.application.credentials.admin_password
    return unless admin_password.present?

    User.create!(
      email_address: ApplicationController::ADMIN_EMAIL,
      password: admin_password,
      password_confirmation: admin_password
    )
  end
end
