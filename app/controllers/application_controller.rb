class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  allow_browser versions: :modern
  before_action :configure_permitted_parameters, if: :devise_controller?
  layout :choose_layout

  private

  def choose_layout
    devise_controller? ? "devise" : "application"
  end

  protected

  def require_admin
    unless current_user && current_user.role&.name == "admin"
      redirect_to root_path, alert: t("flash.application.access_denied")
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username, :role_id])
    devise_parameter_sanitizer.permit(:account_update, keys: [:username])
  end
end
