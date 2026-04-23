class VisitorsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_visitor, only: [ :show, :edit, :update, :regenerate_qr ]
  before_action :require_admin, only: [:regenerate_qr]

  PER_PAGE = 10

  def index
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
    @visitor.cpf = params[:identifier].gsub(/\D/, "") if params[:identifier].present?
  end

  def create
    @visitor = Visitor.new(visitor_params)

    if @visitor.save
      redirect_to visitors_path, notice: t("flash.visitors.created", name: @visitor.name)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  def edit
  end

  def update
    if @visitor.update(visitor_params)
      redirect_to @visitor, notice: t("flash.visitors.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def regenerate_qr
    QrCodeGeneratorService.generate_and_assign(@visitor)

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

  private

  def set_visitor
    @visitor = Visitor.find(params[:id])
  end

  def visitor_params
    params.require(:visitor).permit(:name, :cpf, :email)
  end
end
