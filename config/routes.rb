Rails.application.routes.draw do
  devise_for :users

  root "access#identification"
  get "identify", to: "access#identification", as: :identify
  post "identify", to: "access#process_identification"
  get "menu", to: "daily_menus#today", as: :public_menu

  resources :students do
    post :regenerate_qr, on: :member
  end

  resources :visitors do
    post :regenerate_qr, on: :member
  end

  resources :meals

  resources :daily_menus

  resources :access_logs, only: [:index, :destroy]
end
