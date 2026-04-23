class AccessLogsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin, only: [:destroy]
  before_action :set_access_log, only: [:destroy]

  PER_PAGE = 10

  def index
    @page = (params[:page] || 1).to_i
    @access_logs = AccessLog.includes(:personable)
                            .order(created_at: :desc)
                            .offset((@page - 1) * PER_PAGE)
                            .limit(PER_PAGE)
    @has_more = AccessLog.count > @page * PER_PAGE
  end

  def destroy
    @access_log.destroy!

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove("access_log_#{@access_log.id}") }
      format.html { redirect_to access_logs_url, notice: t("flash.access_logs.destroyed") }
    end
  end

  private

  def set_access_log
    @access_log = AccessLog.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to access_logs_url, alert: t("flash.access_logs.not_found")
  end
end
