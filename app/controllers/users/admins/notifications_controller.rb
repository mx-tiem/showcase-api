class Users::Admins::NotificationsController < Users::AdminsController
  include Pagy::Method

  def index
    sort_by, sort_direction = extract_sort_params(%w[id title read created_at])
    collection = Notification.includes(:user).order(sort_by => sort_direction)

    pagy, notifications = pagy(:offset, collection, limit: pagination_params[:per_page] || 10)
    render json: {
      notifications: serialize_notifications(notifications),
      pagy: pagy_metadata(pagy)
    }
  end

  def notifications_for_user
    user = User.find(params[:user_id])
    collection = user.notifications.order(created_at: :desc)

    pagy, notifications = pagy(:offset, collection, limit: pagination_params[:per_page] || 10)
    render json: {
      notifications: serialize_notifications(notifications),
      pagy: pagy_metadata(pagy)
    }
  end

  private

  def pagination_params
    params.permit(:per_page, :page)
  end

  def extract_sort_params(allowed_fields)
    sort_by = allowed_fields.include?(params[:sort_by]) ? params[:sort_by] : "created_at"
    sort_direction = %w[asc desc].include?(params[:sort_direction]) ? params[:sort_direction] : "desc"
    [ sort_by, sort_direction ]
  end

  def pagy_metadata(pagy)
    {
      current_page: pagy.page,
      total_pages: pagy.pages,
      total_count: pagy.count,
      per_page: pagy.limit
    }
  end

  def serialize_notifications(notifications)
    AdminNotificationSerializer.new(notifications).serializable_hash[:data].map { |n| n[:attributes] }
  end
end
