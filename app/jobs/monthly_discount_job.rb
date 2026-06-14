class MonthlyDiscountJob < ApplicationJob
  queue_as :default

  def perform(date = nil)
    settings = AppSetting.instance
    max_discount = settings.max_play_discount
    max_hours = settings.max_play_discount_hours_required

    target_date = date ? Date.parse(date) : 1.month.ago
    start_of_month = target_date.beginning_of_month
    end_of_month = target_date.end_of_month

    users_with_done_reservations = User
      .joins(:reservations)
      .where(reservations: { status: "done", start_time: start_of_month..end_of_month })
      .distinct

    users_with_done_reservations.find_each do |user|
      played_hours = user.reservations
        .where(status: "done")
        .where(start_time: start_of_month..end_of_month)
        .sum { |r| r.duration_in_hours }

      discount = if played_hours >= max_hours
        max_discount
      else
        (played_hours.to_f / max_hours * max_discount).round(2)
      end

      user.update!(discount_play: discount, played_hours: played_hours)

      month_name = start_of_month.strftime("%B %Y")
      Notification.create!(
        user_id: user.id,
        title: "Monthly Discount Updated",
        short_description: "You earned a #{discount}% discount for #{month_name}.",
        long_description: "Based on #{played_hours}h played in #{month_name}, your play discount has been updated to #{discount}%. Keep playing to increase it!",
        icon: "percent"
      )
    end
  end
end
