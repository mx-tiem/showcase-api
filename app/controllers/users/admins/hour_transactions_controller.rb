class Users::Admins::HourTransactionsController < Users::AdminsController
  include Pagy::Method

  def index
    collection = HourTransaction.includes(:sender, :receiver)
    collection = apply_sorting(collection)

    pagy, hour_transactions = pagy(:offset, collection, limit: pagination_params[:per_page] || 10)
    render json: {
      hour_transactions: serialize_hour_transactions(hour_transactions),
      pagy: pagy_metadata(pagy)
    }
  end

  def create
    hour_transaction = HourTransaction.new(hour_transaction_params)

    if hour_transaction.save
      render json: serialize_hour_transaction(hour_transaction), status: :created
    else
      render json: { errors: hour_transaction.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def hour_transaction_params
    params.require(:hour_transaction).permit(:sender_id, :receiver_id, :receiver_type, :hours_amount, :transaction_type, :notice)
  end

  def pagination_params
    params.permit(:per_page, :page)
  end

  def sorting_params
    params.permit(:sort_by, :sort_direction)
  end

  def apply_sorting(collection)
    sort_by, sort_direction = extract_sort_params(%w[id sender_id receiver_id receiver_type hours_amount transaction_type created_at updated_at])
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

  def serialize_hour_transaction(hour_transaction)
    AdminHourTransactionSerializer.new(hour_transaction).serializable_hash[:data][:attributes]
  end

  def serialize_hour_transactions(hour_transactions)
    AdminHourTransactionSerializer.new(hour_transactions).serializable_hash[:data].map { |ht| ht[:attributes] }
  end

  def extract_sort_params(allowed_fields)
    sort_prms = sorting_params
    sort_by = sort_prms[:sort_by] || "id"
    sort_direction = sort_prms[:sort_direction]&.downcase == "desc" ? :desc : :asc
    sort_by = "id" unless allowed_fields.include?(sort_by)
    [ sort_by, sort_direction ]
  end
end
