class Users::AdminsController < ApplicationController
  include Pagy::Method
  before_action :authenticate_user!
  before_action :authorize_admin

  def authorize_admin
    unless current_user.role == "admin"
      render json: { error: "Unauthorized access" }, status: :unauthorized
    end
  end
end
