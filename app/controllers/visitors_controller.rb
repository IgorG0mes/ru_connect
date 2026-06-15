class VisitorsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_visitor, only: [ :show, :edit, :update, :regenerate_qr, :send_qr_email, :destroy ]

  PER_PAGE = 10

  def index
    authorize Visitor
    @searched = params[:q].present?
    return unless @searched

    base = Visitor.where("unaccent(name) ILIKE unaccent(?) OR cpf ILIKE ?", "%#{params[:q]}%", "%#{params[:q]}%")
    @page = (params[:page] || 1).to_i
    @total = base.count
    @has_more = @total > @page * PER_PAGE
    @visitors = base.order(:name).offset((@page - 1) * PER_PAGE).limit(PER_PAGE)
  end

  def new
    @visitor = Visitor.new
    authorize @visitor
    @visitor.cpf = params[:identifier].gsub(/\D/, "") if params[:identifier].present?
  end

  def create
    @visitor = Visitor.new(visitor_params)
    authorize @visitor

    if @visitor.save
      QrCodeMailer.welcome(@visitor).deliver_later if @visitor.email.present?
      redirect_to visitors_path, notice: t("flash.visitors.created", name: @visitor.name)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    authorize @visitor
  end

  def edit
    authorize @visitor
  end

  def update
    authorize @visitor
    if @visitor.update(visitor_params)
      redirect_to @visitor, notice: t("flash.visitors.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @visitor
    @visitor.destroy
    redirect_to visitors_path, notice: t("flash.visitors.deleted", name: @visitor.name)
  end

  def regenerate_qr
    authorize @visitor
    QrCodeGeneratorService.generate_and_assign(@visitor)
    QrCodeMailer.qr_code_regenerated(@visitor).deliver_later if @visitor.email.present?

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "qr_code_visitor_#{@visitor.id}",
          partial: "visitors/qr_code",
          locals: { visitor: @visitor }
        )
      end
      format.html { redirect_to @visitor, notice: t("flash.visitors.qr_regenerated", name: @visitor.name) }
    end
  end

  def send_qr_email
    authorize @visitor
    if @visitor.email.blank?
      redirect_to @visitor, alert: t("flash.visitors.no_email")
      return
    end
    QrCodeMailer.send_qr_code(@visitor).deliver_later
    redirect_to @visitor, notice: t("flash.visitors.qr_email_sent", email: @visitor.email)
  end

  private

  def set_visitor
    @visitor = Visitor.find(params[:id])
  end

  def visitor_params
    params.require(:visitor).permit(:name, :cpf, :email)
  end
end
