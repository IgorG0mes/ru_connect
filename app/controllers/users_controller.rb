class UsersController < ApplicationController
  before_action :require_admin
  before_action :set_user, only: [:edit, :update, :destroy]

  def index
    @users = User.includes(:role).order(:username)
  end

  def new
    @user = User.new
    @roles = Role.all.order(:name)
  end

  def create
    @user = User.new(user_create_params)
    if @user.save
      redirect_to users_path, notice: t("flash.users.created", name: @user.username)
    else
      @roles = Role.all.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @roles = Role.all.order(:name)
  end

  def update
    update_params = user_update_params
    if update_params[:password].blank?
      update_params.delete(:password)
      update_params.delete(:password_confirmation)
    end

    if @user.update(update_params)
      redirect_to users_path, notice: t("flash.users.updated", name: @user.username)
    else
      @roles = Role.all.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user == current_user
      redirect_to users_path, alert: t("flash.users.cannot_delete_self")
      return
    end

    @user.destroy!
    redirect_to users_path, notice: t("flash.users.destroyed")
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_create_params
    params.require(:user).permit(:username, :email, :password, :password_confirmation, :role_id)
  end

  def user_update_params
    params.require(:user).permit(:username, :email, :password, :password_confirmation, :role_id)
  end
end
