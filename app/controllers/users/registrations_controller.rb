class Users::RegistrationsController < Devise::RegistrationsController
  before_action :authenticate_user!, only: [:new, :create]
  before_action only: [:new, :create] do
    authorize User
  end
end
