class ApplicationController < ActionController::Base
  include Pundit::Authorization

  before_action :authenticate_user!
  allow_browser versions: :modern
  before_action :configure_permitted_parameters, if: :devise_controller?
  layout :choose_layout

  rescue_from Pundit::NotAuthorizedError, with: :pundit_not_authorized

  private

  def pundit_not_authorized
    redirect_to root_path, alert: t("flash.application.access_denied")
  end

  def choose_layout
    devise_controller? ? "devise" : "application"
  end

  protected

  def after_sign_in_path_for(resource)
    identify_path
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username, :role_id])
    devise_parameter_sanitizer.permit(:account_update, keys: [:username])
  end
end
