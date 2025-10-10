class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  allow_browser versions: :modern

  protected

  def require_admin
    unless current_user && current_user.role&.name == "admin"
      redirect_to root_path, alert: "Acesso negado. Você não tem permissões administrativas para esta ação."
    end
  end
end
