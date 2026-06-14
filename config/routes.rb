Rails.application.routes.draw do
  devise_for :users, path: "", path_names: {
    sign_in: "login",
    sign_out: "logout",
    registration: "signup"
  },
  controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations"
  }

  get "current_user", to: "users/users#get_current_user"

  scope "admin" do
    resources :users, only: [ :index, :create, :update, :destroy, :show ], controller: "users/admins/users"
    resources :machines, only: [ :index, :create, :update, :destroy, :show ], controller: "users/admins/machines"
    resources :games, only: [ :index, :create, :update, :destroy, :show ], controller: "users/admins/games"
    resources :prices, only: [ :index, :create, :update, :destroy, :show ], controller: "users/admins/prices"

    resources :reservations, only: [ :index, :create, :update, :show ], controller: "users/admins/reservations"
    post "reservations/:id/cancel", to: "users/admins/reservations#cancel"
    post "reservations/:id/cancel_late", to: "users/admins/reservations#cancel_late_reservation"
    get "reservations/:id/max_extend", to: "users/admins/reservations#max_extend"
    post "reservations/:id/extend", to: "users/admins/reservations#extend"
    get "reservations/machine_reservations/:machine_id", to: "users/admins/reservations#reservations_for_machine"
    get "reservations/user_reservations/:user_id", to: "users/admins/reservations#reservations_for_user"
    post "reservations/check_availability/", to: "users/admins/reservations#check_availability"
    get "reservations/calendar_user_reservations/:user_id", to: "users/admins/reservations#calendar_user_reservations"

    resources :machine_hours, only: [ :create, :destroy ], controller: "users/admins/machine_hours"
    get "playhours_for_user/:user_id", to: "users/admins/machine_hours#playhours_for_user"
    get "total_hours_for_user/:user_id", to: "users/admins/machine_hours#total_hours_for_user"

    get "game_plays_for_user/:user_id", to: "users/admins/game_plays#game_plays_for_user"

    resources :hour_transactions, only: [ :index ], controller: "users/admins/hour_transactions"

    resource :app_setting, only: [ :show, :update ], controller: "users/admins/app_settings" do
      post :reset, on: :member
    end

    post "discounts/execute_monthly_discount", to: "users/admins/discounts#execute_monthly_discount"

    resources :notifications, only: [ :index, :show, :create, :update, :destroy ], controller: "users/admins/notifications"
    get "notifications_for_user/:user_id", to: "users/admins/notifications#notifications_for_user"
  end

  scope "user" do
    get "current_user", to: "users/users/active_user#get_current_user"
    get "user_search", to: "users/users/friends#user_search"
    post "check_availability", to: "users/users/reservations#check_availability"

    resources :friends, only: [ :index, :create, :destroy ], controller: "users/users/friends"

    resources :reservations, only: [ :index, :create ], controller: "users/users/reservations"
    scope "reservations" do
      post "cancel", to: "users/users/reservations#cancel_reservation"
      get "active", to: "users/users/reservations#active"
      post "extend", to: "users/users/reservations#extend"
      get ":id/max_extend", to: "users/users/reservations#max_extend"
    end

    get "app_settings", to: "users/users/app_settings#show"
    get "machines", to: "users/users/machines#index"
    get "prices", to: "users/users/prices#index"
    get "game_plays_summary", to: "users/users/game_plays#summary"

    resources :notifications, only: [ :index ], controller: "users/users/notifications"
    scope "notifications" do
      get "dropdown", to: "users/users/notifications#dropdown"
      post "mark_all_read", to: "users/users/notifications#mark_all_as_read"
      post ":id/read", to: "users/users/notifications#mark_as_read"
    end
  end

  # Warden routes (machine authentication & control)
  post "warden-login", to: "warden#login"
  post "warden-report", to: "warden#report"
  get "warden-status/:machine_id", to: "warden#status"
  post "warden-command", to: "warden#command"
  post "warden-start-gameplay", to: "warden#start_gameplay"
  post "warden-end-gameplay", to: "warden#end_gameplay"
  post "warden-user-logged-out", to: "warden#user_logged_out"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
