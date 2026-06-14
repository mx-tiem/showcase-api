class Users::Admins::UsersController < Users::AdminsController
  include Pagy::Method

  def index
    sort_by, sort_direction = extract_sort_params(%w[id email name role available_playhours])

    if sort_by == "available_playhours"
      users, pagy_info = sort_and_paginate_by_playhours(sort_direction)
    else
      collection = User.order(sort_by => sort_direction)
      pagy, users = pagy(:offset, collection, limit: pagination_params[:per_page] || 10)
      pagy_info = pagy_metadata(pagy)
    end

    render json: {
      users: serialize_users(users),
      pagy: pagy_info
    }
  end

  def show
    user = User.find(params[:id])
    render json: serialize_user(user)
  end

  def create
    user = User.new(user_params)

    if user.save
      render json: serialize_user(user), status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    user = User.find(params[:id])
    discount_changed = user_params.key?(:discount_admin) && user.discount_admin != user_params[:discount_admin].to_f

    if user.update(user_params)
      if discount_changed
        Notification.create!(
          user_id: user.id,
          title: "Admin Discount Updated",
          short_description: "Your admin discount has been set to #{user.discount_admin}%.",
          long_description: "An administrator has updated your admin discount to #{user.discount_admin}%. This discount will be applied to your future reservations.",
          icon: "percent"
        )
      end
      render json: serialize_user(user)
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    user = User.find(params[:id])
    user.destroy
    head :no_content
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :name, :username, :role, :discount_admin)
  end

  def pagination_params
    params.permit(:per_page, :page)
  end

  def sorting_params
    params.permit(:sort_by, :sort_direction)
  end

  def pagy_metadata(pagy)
    {
      current_page: pagy.page,
      total_pages: pagy.pages,
      total_count: pagy.count,
      per_page: pagy.limit
    }
  end

  def serialize_user(user)
    AdminUserSerializer.new(user).serializable_hash[:data][:attributes]
  end

  def serialize_users(users)
    AdminUserSerializer.new(users).serializable_hash[:data].map { |u| u[:attributes] }
  end

  def extract_sort_params(allowed_fields)
    sort_prms = sorting_params
    sort_by = sort_prms[:sort_by] || "id"
    sort_direction = sort_prms[:sort_direction]&.downcase == "desc" ? :desc : :asc
    sort_by = "id" unless allowed_fields.include?(sort_by)
    [ sort_by, sort_direction ]
  end

  def sort_and_paginate_by_playhours(sort_direction)
    # Use database-level aggregation and sorting for available_playhours
    # This avoids loading all users into memory
    base_query = User.joins(:machine_hours)
                     .where(machine_hours: { hours_type: :playhours, hours_status: :active })
                     .where("machine_hours.expires = ? OR (machine_hours.expires = ? AND machine_hours.expires_at > ?)",
                            false, true, Time.current)
                     .group("users.id")
                     .having("SUM(machine_hours.hours_amount) > 0")
                     .order("SUM(machine_hours.hours_amount) #{sort_direction.to_s.upcase}")

    pagy, users = pagy(:offset, base_query, limit: pagination_params[:per_page] || 10)
    pagy_info = pagy_metadata(pagy)

    # Load associations for the paginated results only
    users_with_associations = User.includes(:machine_hours).where(id: users.map(&:id))

    [ users_with_associations, pagy_info ]
  end
end
