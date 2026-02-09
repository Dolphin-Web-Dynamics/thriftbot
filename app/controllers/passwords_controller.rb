class PasswordsController < ApplicationController
  rate_limit to: 10, within: 3.minutes, only: :update

  def edit
  end

  def update
    if current_user.authenticate(params[:current_password])
      if current_user.update(password_params)
        redirect_to root_path, notice: "Password updated successfully."
      else
        flash.now[:alert] = current_user.errors.full_messages.to_sentence
        render :edit, status: :unprocessable_entity
      end
    else
      flash.now[:alert] = "Current password is incorrect."
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def password_params
    params.permit(:password, :password_confirmation)
  end
end
