Rails.application.routes.draw do
  root "books#index"

  resources :books, only: [ :index, :show ]
  resource  :import, only: [ :new, :create, :show ]
  resources :authors, only: [ :index, :show ]
end
