class Users::Admins::PricesController < Users::AdminsController
  include Pagy::Method

  def index
    collection = Price
    collection = apply_sorting(collection)
    pagy, prices = pagy(:offset, collection, limit: pagination_params[:per_page] || 10)

    render json: {
      prices: serialize_prices(prices),
      pagy: pagy_metadata(pagy)
    }
  end

  def show
    render json: serialize_price(find_price)
  end

  def create
    price = Price.new(price_params)

    if price.save
      render json: serialize_price(price), status: :created
    else
      render json: { errors: price.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    price = find_price

    if price.update(price_params)
      render json: serialize_price(price)
    else
      render json: { errors: price.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    find_price.destroy
    head :no_content
  end

  private

  def find_price
    Price.find(params[:id])
  end

  def price_params
    params.require(:price).permit(:name, :description, :price, :amount, :hours_type, :active, :currency, :sort_order)
  end

  def serialize_price(price)
    AdminPriceSerializer.new(price).serializable_hash[:data][:attributes]
  end

  def serialize_prices(prices)
    AdminPriceSerializer.new(prices).serializable_hash[:data].map { |p| p[:attributes] }
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
    sort_by, sort_direction = extract_sort_params(%w[id name price amount hours_type active currency sort_order created_at])
    collection.order(sort_by => sort_direction)
  end

  def extract_sort_params(allowed_fields)
    sort_prms = sorting_params
    sort_by = sort_prms[:sort_by] || "sort_order"
    sort_direction = sort_prms[:sort_direction]&.downcase == "desc" ? :desc : :asc
    sort_by = "sort_order" unless allowed_fields.include?(sort_by)
    [ sort_by, sort_direction ]
  end
end
