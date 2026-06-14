class Users::Admins::DiscountsController < Users::AdminsController
  def execute_monthly_discount
    MonthlyDiscountJob.perform_later(params[:month])
    render json: { message: "Monthly discount job has been enqueued" }, status: :ok
  end
end
