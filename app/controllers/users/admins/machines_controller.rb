class Users::Admins::MachinesController < Users::AdminsController
  include Pagy::Method

  def index
    collection = Machine
    collection = apply_sorting(collection)
    pagy, machines = pagy(:offset, collection, limit: pagination_params[:per_page] || 10)

    render json: {
      machines: serialize_machines(machines),
      pagy: pagy_metadata(pagy)
    }
  end

  def show
    render json: serialize_machine(find_machine)
  end

  def create
    machine = Machine.new(machine_params)

    if machine.save
      render json: serialize_machine(machine), status: :created
    else
      render json: { errors: machine.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    machine = find_machine

    if machine.update(machine_params)
      render json: serialize_machine(machine)
    else
      render json: { errors: machine.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    find_machine.destroy
    head :no_content
  end

  private

  def find_machine
    Machine.find(params[:id])
  end

  def machine_params
    params.require(:machine).permit(:name, :machine_type, :status, :hardware_configuration, :start_work_hours, :end_work_hours, :reservation_priority, :warden_callback_secret, :warden_callback_port, :warden_global_ip, :warden_local_ip, working_days: [])
  end

  def serialize_machine(machine)
    AdminMachineSerializer.new(machine).serializable_hash[:data][:attributes]
  end

  def serialize_machines(machines)
    AdminMachineSerializer.new(machines).serializable_hash[:data].map { |m| m[:attributes] }
  end

  def pagination_params
    params.permit(:per_page, :page)
  end

  def sorting_params
    params.permit(:sort_by, :sort_direction)
  end

  def pagy_metadata(pagy)
    {
      current_page: pagy.page,
      total_pages: pagy.pages,
      total_count: pagy.count,
      per_page: pagy.limit
    }
  end

  def apply_sorting(collection)
    sort_by, sort_direction = extract_sort_params(%w[id name machine_type status start_work_hours end_work_hours])
    collection.order(sort_by => sort_direction)
  end

  def extract_sort_params(allowed_fields)
    sort_prms = sorting_params
    sort_by = sort_prms[:sort_by] || "id"
    sort_direction = sort_prms[:sort_direction]&.downcase == "desc" ? :desc : :asc
    sort_by = "id" unless allowed_fields.include?(sort_by)
    [ sort_by, sort_direction ]
  end
end
