# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# App settings (singleton — only one instance should exist)
unless AppSetting.exists?
  AppSetting.create!(
    opening_hours: "14:00",
    closing_hours: "22:00",
    working_days: %w[monday tuesday wednesday thursday friday saturday sunday],
    free_cancellation_hours: 4,
    min_hours_before_reservation: 2
  )
  puts "AppSetting created."
else
  puts "AppSetting already exists, skipping."
end
