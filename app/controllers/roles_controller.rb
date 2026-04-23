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
      redirect_to roles_path, notice: t("flash.roles.created", name: @role.name)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @role.update(role_params)
      redirect_to roles_path, notice: t("flash.roles.updated", name: @role.name)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
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
