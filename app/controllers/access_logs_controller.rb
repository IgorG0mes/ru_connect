class AccessLogsController < ApplicationController
  before_action :authenticate_user!

  before_action :require_admin, only: [:destroy]
  before_action :set_access_log, only: [:destroy]

  def index
    @access_logs = AccessLog.order(created_at: :desc).limit(500)
  end

  def destroy
    @access_log.destroy!
    redirect_to access_logs_url, notice: "Registro de acesso excluído com sucesso."
  end

  private

  def set_access_log
    @access_log = AccessLog.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to access_logs_url, alert: "Registro de acesso não encontrado."
  end
end
