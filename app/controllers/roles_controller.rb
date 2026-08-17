class RolesController < ApplicationController
  before_action :set_role, only: [:edit, :update, :destroy]

  def index
    authorize Role
    @roles = Role.all.order(:name)
  end

  def new
    authorize Role
    @role = Role.new
  end

  def create
    @role = Role.new(role_params)
    authorize @role
    if @role.save
      redirect_to roles_path, notice: t("flash.roles.created", name: @role.name)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @role
  end

  def update
    authorize @role
    if @role.update(role_params)
      redirect_to roles_path, notice: t("flash.roles.updated", name: @role.name)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @role
    @role.destroy!

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove("role_#{@role.id}") }
      format.html { redirect_to roles_path, notice: t("flash.roles.destroyed") }
    end
  end

  private

  def set_role
    @role = Role.find(params[:id])
  end

  def role_params
    params.require(:role).permit(:name)
  end
end
