Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  devise_for :users

  root "dashboard#show"

  get "dashboard", to: "dashboard#show", as: :dashboard
  resources :games, only: [:new, :create, :show] do
    resources :responses, only: :create
  end

  post "topics/generate", to: "topics#generate"

  resources :topics, only: [] do
    resources :questions, only: [:index, :destroy]
  end
end
