class Users::Admins::MachineHoursController < Users::AdminsController
  include Pagy::Method

  def playhours_for_user
    render_user_hours(:playhours)
  end

  def total_hours_for_user
    user = find_user
    hours_type = hours_type_params[:hours_type] || "playhours"

    render json: {
      active: user.machine_hours.where(hours_type: hours_type, hours_status: :active).sum(:hours_amount),
      used: user.machine_hours.where(hours_type: hours_type, hours_status: :used).sum(:hours_amount)
    }
  end

  def create
    machine_hour = MachineHour.new(machine_hour_params)

    if machine_hour.save
      create_hour_transaction(machine_hour, "add_admin_to_user")

      Notification.create!(
        user_id: machine_hour.user_id,
        title: "Hours Added",
        short_description: "#{machine_hour.hours_amount}h of #{machine_hour.hours_type} added to your account.",
        long_description: "An admin added #{machine_hour.hours_amount} hours of #{machine_hour.hours_type} to your account.",
        icon: "more_time"
      )

      render json: serialize_machine_hour(machine_hour), status: :created
    else
      render json: { errors: machine_hour.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    machine_hour = MachineHour.find(params[:id])

    if machine_hour.destroy
      create_removal_transaction(machine_hour)
      head :no_content
    else
      render json: { errors: machine_hour.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def machine_hour_params
    params.require(:machine_hour).permit(:user_id, :hours_amount, :hours_type, :hours_status, :expires, :expires_at)
  end

  def pagination_params
    params.permit(:per_page, :page)
  end

  def sorting_params
    params.permit(:sort_by, :sort_direction)
  end

  def user_filter_params
    params.permit(:user_id)
  end

  def hours_type_params
    params.permit(:hours_type)
  end

  def apply_sorting(collection)
    sort_by, sort_direction = extract_sort_params(%w[id hours_amount hours_type expires expires_at created_at updated_at user_id])
    collection.order(sort_by => sort_direction)
  end

  def pagy_metadata(pagy)
    {
      current_page: pagy.page,
      total_pages: pagy.pages,
      total_count: pagy.count,
      per_page: pagy.limit
    }
  end

  # Helper methods
  def find_user
    User.find(user_filter_params[:user_id])
  end

  def render_user_hours(hours_type)
    user = find_user
    collection = apply_sorting(user.machine_hours.includes(:user).where(hours_type: hours_type))
    pagy, machine_hours = pagy(:offset, collection, limit: pagination_params[:per_page] || 10)

    render json: {
      machine_hours: serialize_machine_hours(machine_hours),
      pagy: pagy_metadata(pagy)
    }
  end

  def serialize_machine_hour(machine_hour)
    AdminMachineHourSerializer.new(machine_hour).serializable_hash[:data][:attributes]
  end

  def serialize_machine_hours(machine_hours)
    AdminMachineHourSerializer.new(machine_hours).serializable_hash[:data].map { |mh| mh[:attributes] }
  end

  def extract_sort_params(allowed_fields)
    sort_prms = sorting_params
    sort_by = sort_prms[:sort_by] || "id"
    sort_direction = sort_prms[:sort_direction]&.downcase == "desc" ? :desc : :asc
    sort_by = "id" unless allowed_fields.include?(sort_by)
    [ sort_by, sort_direction ]
  end

  def create_hour_transaction(machine_hour, transaction_type)
    HourTransaction.create!(
      sender_id: current_user.id,
      receiver_id: machine_hour.user_id,
      receiver_type: "User",
      hours_amount: machine_hour.hours_amount,
      transaction_type: transaction_type,
      notice: "Admin created #{machine_hour.hours_amount} #{machine_hour.hours_type} hours"
    )
  end

  def create_removal_transaction(machine_hour)
    HourTransaction.create!(
      sender_id: machine_hour.user_id,
      receiver_id: current_user.id,
      receiver_type: "User",
      hours_amount: machine_hour.hours_amount,
      transaction_type: "remove_admin_to_user",
      notice: "Admin removed #{machine_hour.hours_amount} #{machine_hour.hours_type} hours"
    )
  end
end
