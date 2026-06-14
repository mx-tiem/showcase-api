class AdminAppSettingSerializer
  include JSONAPI::Serializer
  attributes :id, :working_days, :free_cancellation_hours, :min_hours_before_reservation, :max_play_discount_hours_required, :start_late_tolerance

  attribute :opening_hours do |object|
    object.opening_hours&.strftime("%H:%M")
  end

  attribute :closing_hours do |object|
    object.closing_hours&.strftime("%H:%M")
  end

  attribute :max_play_discount do |object|
    object.max_play_discount&.to_f
  end
end
