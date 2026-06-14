class AdminMachineSerializer
  include JSONAPI::Serializer
  attributes :id, :name, :machine_type, :status, :hardware_configuration, :working_days, :reservation_priority,
             :warden_global_ip, :warden_local_ip, :warden_callback_port, :warden_callback_secret

  attribute :start_work_hours do |object|
    object.start_work_hours&.strftime("%H:%M")
  end

  attribute :end_work_hours do |object|
    object.end_work_hours&.strftime("%H:%M")
  end
end
