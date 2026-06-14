class Users::Users::FriendsController < Users::UsersController
  include Pagy::Method

  def index
    friendships = current_user.friends
    friend_ids = friendships.pluck(:friend_id)
    friend_users = User.where(id: friend_ids).index_by(&:id)
    render json: {
      friends: serialize_friends(friendships, friend_users)
    }
  end

  def create
    if current_user.friends.exists?(friend_id: friend_params[:friend_id])
      render json: { error: "Already friends" }, status: :unprocessable_entity
    else
      friendship = current_user.friends.create(friend_id: friend_params[:friend_id])
      if friendship.persisted?
        friend_user = User.find(friendship.friend_id)
        render json: { friend: UserUserSerializer.new(friend_user).serializable_hash[:data][:attributes] }, status: :created
      else
        render json: { errors: friendship.errors }, status: :unprocessable_entity
      end
    end
  end

  def destroy
    friendship = current_user.friends.find_by(friend_id: params[:id])
    if friendship
      friendship.destroy
      head :no_content
    else
      render json: { error: "Friend not found" }, status: :not_found
    end
  end

  def user_search
    search_term = user_search_params[:search_query]
    if search_term.present?
      users = User.where("email ILIKE ? OR name ILIKE ? OR username ILIKE ?", "%#{search_term}%", "%#{search_term}%", "%#{search_term}%")
                  .where.not(id: current_user.id)
                  .where.not(id: current_user.friends.select(:friend_id))
      pagy, paginated_users = pagy(:offset, users, limit: pagination_params[:per_page] || 10)
      render json: {
        users: serialize_users(paginated_users),
        pagy: pagy_metadata(pagy)
      }
    else
      render json: { error: "Search term is required" }, status: :bad_request
    end
  end

  private

  def friend_params
    params.permit(:friend_id)
  end

  def user_search_params
    params.permit(:search_query)
  end

  def pagination_params
    params.permit(:per_page, :page)
  end

  def pagy_metadata(pagy)
    {
      current_page: pagy.page,
      total_pages: pagy.pages,
      total_count: pagy.count,
      per_page: pagy.limit
    }
  end

  def serialize_users(users)
    UserUserSerializer.new(users).serializable_hash[:data].map { |u| u[:attributes] }
  end

  def serialize_friends(friendships, friend_users)
    friendships.map { |f| UserUserSerializer.new(friend_users[f.friend_id]).serializable_hash[:data][:attributes] }
  end
end
