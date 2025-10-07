Rails.application.routes.draw do
  devise_for :users

  root "access#identification"
  get "identify", to: "access#identification"
  post "identify", to: "access#process_identification"

  resources :students
  resources :visitors
  resources :meals
  resources :daily_menus
end
