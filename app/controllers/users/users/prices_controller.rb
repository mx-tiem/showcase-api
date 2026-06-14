class Users::Users::PricesController < Users::UsersController
  def index
    prices = Price.active.sorted

    discount = [ current_user.discount_play.to_f + current_user.discount_admin.to_f, 100.0 ].min

    render json: {
      prices: prices.map { |price| serialize_price(price, discount) },
      discount: discount,
      discount_play: current_user.discount_play.to_f,
      discount_admin: current_user.discount_admin.to_f
    }
  end

  private

  def serialize_price(price, discount)
    base_price = price.price.to_f
    discounted_price = discount > 0 ? (base_price * (1 - discount / 100.0)).round(2) : nil

    {
      id: price.id,
      name: price.name,
      description: price.description,
      price: base_price,
      discounted_price: discounted_price,
      amount: price.amount,
      hours_type: price.hours_type,
      currency: price.currency
    }
  end
end
