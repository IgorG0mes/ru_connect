class Users::RegistrationsController < Devise::RegistrationsController
  before_action :authenticate_user!, :require_admin, only: [:new, :create]
end
