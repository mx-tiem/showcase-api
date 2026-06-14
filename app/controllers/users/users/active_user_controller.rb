class Users::Users::ActiveUserController < Users::UsersController
  def get_current_user
    render json: current_user.as_json(only: [ :id, :email, :name, :role, :username ], methods: [ :available_playhours ])
  end

  def update_current_user
    if needs_password_update?
      unless current_user.valid_password?(current_user_params[:current_password])
        return render json: { errors: [ "Current password is incorrect" ] }, status: :unprocessable_entity
      end
    end

    if current_user.update(update_params)
      render json: current_user.as_json(only: [ :id, :email, :name, :role, :username ], methods: [ :available_playhours ])
    else
      render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def current_user_params
    params.require(:user).permit(:email, :username, :name, :password, :password_confirmation, :current_password)
  end

  def update_params
    # Only include password fields if a new password is being set
    permitted = current_user_params.except(:current_password)
    if permitted[:password].blank?
      permitted.except(:password, :password_confirmation)
    else
      permitted
    end
  end

  def needs_password_update?
    current_user_params[:password].present?
  end
end
