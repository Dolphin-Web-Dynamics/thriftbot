class RegistrationsController < ApplicationController
  skip_before_action :require_login
  skip_before_action :set_tenant
  skip_before_action :check_subscription

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)
    if @user.save
      session[:user_id] = @user.id
      redirect_to dashboard_path, notice: "Welcome to ThriftBot! Your 14-day free trial has started."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end
