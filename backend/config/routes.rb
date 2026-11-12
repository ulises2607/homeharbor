Rails.application.routes.draw do
  get "up", to: "rails/health#show"
  # Keep Devise's model mapping, without parallel HTML authentication endpoints.
  devise_for :users, skip: :all
  namespace :api do
    namespace :v1 do
      get "session/csrf", to: "sessions#csrf"
      resource :session, only: %i[show create destroy]
      resources :registrations, only: :create
      resource :confirmations, only: %i[create update]
      resource :passwords, only: %i[create update]
      resources :reservations, only: :create
      resources :boats, only: %i[index show create update] do
        resource :availability, only: :show, controller: "availability"
        resources :photos, only: %i[show create destroy], controller: "boat_photos"
        post :deactivation, on: :member
        post :activation, on: :member
      end
      namespace :me do
        resources :boats, only: %i[index show] do
          resources :reservations, only: :index, controller: "boat_reservations"
        end
        resources :reservations, only: %i[index show] do
          post :cancellation, on: :member
        end
      end
    end
  end
end
