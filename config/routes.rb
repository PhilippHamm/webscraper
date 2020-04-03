Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: 'cars#new'
  resources :cars, only: [:new, :index, :create, :destroy]
  get '/form', to: "cars#form", as: :form
end
