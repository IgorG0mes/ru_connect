class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  allow_browser versions: :modern
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def require_admin
    unless current_user && current_user.role&.name == "admin"
      redirect_to root_path, alert: "Acesso negado. Você não tem permissões administrativas para esta ação."
    end
  end

  def configure_permitted_parameters
    # Permite :username e :role_id durante o cadastro (:sign_up)
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username, :role_id])

    # Opcional: Permite :username durante a edição do perfil (:account_update)
    devise_parameter_sanitizer.permit(:account_update, keys: [:username])
  end
end
