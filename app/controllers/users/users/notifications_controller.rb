class Users::Users::NotificationsController < Users::UsersController
  include Pagy::Method

  def index
    notifications = current_user.notifications.recent
    pagy, paginated_notifications = pagy(:offset, notifications, limit: pagination_params[:per_page] || 20)
    render json: {
      notifications: serialize_notifications(paginated_notifications),
      pagy: pagy_metadata(pagy)
    }
  end

  def dropdown
    notifications = current_user.notifications.recent.limit(3)
    unread_count = current_user.notifications.unread.count
    render json: {
      notifications: serialize_dropdown_notifications(notifications),
      unread_count: unread_count
    }
  end

  def mark_as_read
    notification = current_user.notifications.find(params[:id])
    notification.update!(read: true)
    head :no_content
  end

  def mark_all_as_read
    current_user.notifications.unread.update_all(read: true)
    head :no_content
  end

  private

  def pagination_params
    params.permit(:per_page, :page)
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
    UserNotificationSerializer.new(notifications).serializable_hash[:data].map { |n| n[:attributes] }
  end

  def serialize_dropdown_notifications(notifications)
    UserNotificationDropdownSerializer.new(notifications).serializable_hash[:data].map { |n| n[:attributes] }
  end
end
