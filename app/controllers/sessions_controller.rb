class SessionsController < ApplicationController
  skip_before_action :require_login, only: %i[new create]

  rate_limit to: 10, within: 3.minutes, only: :create

  def new
  end

  def create
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
end
