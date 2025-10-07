class VisitorsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_visitor, only: [ :show, :edit, :update ]

  def index
    @visitors = Visitor.all
  end

  def new
    @visitor = Visitor.new
  end

  def create
    @visitor = Visitor.new(visitor_params)

    if @visitor.save
      redirect_to visitors_path, notice: "Visitante #{@visitor.name} cadastrado com sucesso! QR Code gerado."
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
      redirect_to @visitor, notice: "Visitante atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
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
