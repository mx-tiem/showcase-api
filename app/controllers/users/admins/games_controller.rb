class Users::Admins::GamesController < Users::AdminsController
  include Pagy::Method

  def index
    collection = Game
    collection = apply_sorting(collection)
    pagy, games = pagy(:offset, collection, limit: pagination_params[:per_page] || 10)

    render json: {
      games: serialize_games(games),
      pagy: pagy_metadata(pagy)
    }
  end

  def show
    render json: serialize_game(find_game)
  end

  def create
    game = Game.new(game_params)

    if game.save
      render json: serialize_game(game), status: :created
    else
      render json: { errors: game.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    game = find_game

    if game.update(game_params)
      render json: serialize_game(game)
    else
      render json: { errors: game.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    find_game.destroy
    head :no_content
  end

  private

  def find_game
    Game.find(params[:id])
  end

  def game_params
    params.require(:game).permit(:name, :game_identifier, :description, :genre, :multiplayer, :coop, :controller_support, :platform, :logo)
  end

  def serialize_game(game)
    AdminGameSerializer.new(game).serializable_hash[:data][:attributes]
  end

  def serialize_games(games)
    AdminGameSerializer.new(games).serializable_hash[:data].map { |g| g[:attributes] }
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
    sort_by, sort_direction = extract_sort_params(%w[id name game_identifier genre platform multiplayer coop controller_support])
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
