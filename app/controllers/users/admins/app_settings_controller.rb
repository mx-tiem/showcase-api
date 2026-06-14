class Users::Admins::AppSettingsController < Users::AdminsController
  def show
    render json: serialize_app_setting(app_setting)
  end

  def update
    filtered_params = app_setting_params
    filtered_params.delete(:dojo_warden_secret) if filtered_params[:dojo_warden_secret].blank?

    if app_setting.update(filtered_params)
      render json: serialize_app_setting(app_setting)
    else
      render json: { errors: app_setting.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def reset
    if AppSetting.reset_to_defaults!
      render json: serialize_app_setting(app_setting.reload)
    else
      render json: { errors: app_setting.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def app_setting
    @app_setting ||= AppSetting.instance
  end

  def serialize_app_setting(setting)
    AdminAppSettingSerializer.new(setting).serializable_hash[:data][:attributes]
  end

  def app_setting_params
    params.require(:app_setting).permit(
      :opening_hours,
      :closing_hours,
      :free_cancellation_hours,
      :min_hours_before_reservation,
      :dojo_warden_secret,
      :max_play_discount,
      :max_play_discount_hours_required,
      :start_late_tolerance,
      working_days: []
    )
  end
end
