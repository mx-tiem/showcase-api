class Users::Users::AppSettingsController < Users::UsersController
  def show
    settings = AppSetting.instance
    render json: {
      free_cancellation_hours: settings.free_cancellation_hours,
      opening_hours: settings.opening_hours&.strftime("%H:%M"),
      closing_hours: settings.closing_hours&.strftime("%H:%M"),
      working_days: settings.working_days
    }
  end
end
