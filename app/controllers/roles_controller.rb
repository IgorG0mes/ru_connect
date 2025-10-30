class RolesController < ApplicationController
  before_action :require_admin
  before_action :set_role, only: [:edit, :update, :destroy]

  def index
    @roles = Role.all.order(:name)
  end

  def new
    @role = Role.new
  end

  def create
    @role = Role.new(role_params)
    if @role.save
      redirect_to roles_path, notice: "Role '#{@role.name}' criado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @role.update(role_params)
      redirect_to roles_path, notice: "Role '#{@role.name}' atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @role.destroy!
    redirect_to roles_path, notice: "Role excluído com sucesso."
  end

  private

  def set_role
    @role = Role.find(params[:id])
  end

  def role_params
    params.require(:role).permit(:name)
  end
end
