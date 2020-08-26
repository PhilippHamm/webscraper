Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: 'car_dealers#new'
  resources :cars, only: [:new, :index, :create, :destroy]
  get '/form', to: "cars#form", as: :form
  resources :car_dealers, only: [:new, :index, :create, :destroy]
end
