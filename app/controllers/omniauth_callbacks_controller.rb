class OmniauthCallbacksController < ApplicationController
  skip_before_action :require_login
  skip_forgery_protection only: :create

  def create
    auth = request.env["omniauth.auth"]
    return redirect_to new_session_path, alert: "Could not sign in with Google." unless auth

    user = find_or_create_user(auth)

    if user&.persisted?
      session[:user_id] = user.id
      redirect_to root_path, notice: "Signed in with Google."
    else
      redirect_to new_session_path, alert: "Could not sign in with Google."
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
    Rails.logger.error("OAuth user creation failed: #{e.message}")
    redirect_to new_session_path, alert: "Could not sign in with Google."
  end

  def failure
    redirect_to new_session_path, alert: "Authentication failed: #{params[:message].to_s.humanize}"
  end

  private

  def find_or_create_user(auth)
    # 1. Find by provider + uid (returning Google user)
    user = User.find_by(provider: auth.provider, uid: auth.uid)
    return user if user

    # 2. Find by email and link Google account (existing email user)
    user = User.find_by(email_address: auth.info.email)
    if user
      # Only link if user doesn't already have a different OAuth provider
      if user.provider.blank? && user.uid.blank?
        user.update!(provider: auth.provider, uid: auth.uid)
      end
      return user
    end

    # 3. Create new user (new Google user)
    email_verified = auth.dig("extra", "id_info", "email_verified") ||
                     ActiveModel::Type::Boolean.new.cast(auth.dig("extra", "raw_info", "email_verified"))
    is_admin = email_verified && auth.info.email.strip.downcase == ApplicationController::ADMIN_EMAIL

    User.create!(
      email_address: auth.info.email,
      provider: auth.provider,
      uid: auth.uid,
      password: SecureRandom.hex(32),
      admin: is_admin
    )
  end
end
