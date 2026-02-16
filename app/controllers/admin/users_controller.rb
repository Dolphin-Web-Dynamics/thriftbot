module Admin
  class UsersController < BaseController
    before_action :set_user, only: [ :show, :edit, :update, :grant_free_access, :change_plan ]

    def index
      ActsAsTenant.without_tenant do
        @users = User.order(created_at: :desc)
        @users = @users.where("email_address LIKE ?", "%#{params[:search]}%") if params[:search].present?
      end
    end

    def show
      ActsAsTenant.without_tenant do
        @items_count = @user.items.count
        @sales_count = @user.sales.count
      end
    end

    def edit
    end

    def update
      if @user.update(user_params)
        redirect_to admin_user_path(@user), notice: "User updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def grant_free_access
      @user.update!(
        plan: :business_plan,
        subscription_status: :active,
        subscription_ends_at: nil
      )
      redirect_to admin_user_path(@user), notice: "Free access granted."
    end

    def change_plan
      plan = params[:plan]
      if User.plans.key?(plan)
        @user.update!(plan: plan)
        redirect_to admin_user_path(@user), notice: "Plan changed to #{plan.titleize}."
      else
        redirect_to admin_user_path(@user), alert: "Invalid plan."
      end
    end

    private

    def set_user
      ActsAsTenant.without_tenant do
        @user = User.find(params[:id])
      end
    end

    def user_params
      params.require(:user).permit(:plan, :subscription_status, :trial_ends_at, :subscription_ends_at)
    end
  end
end
