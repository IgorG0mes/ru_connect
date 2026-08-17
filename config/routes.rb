Rails.application.routes.draw do
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  devise_for :users, controllers: { registrations: "users/registrations" }

  # Health check usado pelo Render (e load balancers em geral): retorna 200 se o app subiu.
  get "up" => "rails/health#show", as: :rails_health_check

  root "finder#index"
  get "identify", to: "access#identification", as: :identify
  post "identify", to: "access#process_identification"
  get "menu", to: "daily_menus#today", as: :public_menu

  get "finder", to: "finder#index", as: :finder
  post "finder", to: "finder#search"

  resources :payments, only: [:create]
  get  "carteira/recarga/sucesso",  to: "payments#success",  as: :payment_success
  get  "carteira/recarga/falha",    to: "payments#failure",  as: :payment_failure
  get  "carteira/recarga/pendente", to: "payments#pending",  as: :payment_pending
  post "webhooks/mercadopago",      to: "payments#webhook",  as: :mercadopago_webhook

  resources :students do
    member do
      post :regenerate_qr
      post :send_qr_email
    end
  end

  resources :visitors do
    member do
      post :regenerate_qr
      post :send_qr_email
    end
  end

  resources :meals

  resources :daily_menus

  resources :access_logs, only: [:index, :destroy]

  resources :roles, except: [:show]
  resources :users, path: "admin/users", except: [:show]
  resources :ticket_prices, only: [:index, :update]

  resources :permissions, only: [:index] do
    collection do
      post :toggle
    end
  end
end
