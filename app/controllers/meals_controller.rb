class MealsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_meal, only: [ :show, :edit, :update ]

  def index
    authorize Meal
    @meals = Meal.all
  end

  def new
    @meal = Meal.new
    authorize @meal
  end

  def create
    @meal = Meal.new(meal_params)
    authorize @meal

    if @meal.save
      redirect_to meals_path, notice: t("flash.meals.created", name: @meal.name)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @meal
  end

  def update
    authorize @meal
    if @meal.update(meal_params)
      redirect_to meals_path, notice: t("flash.meals.updated", name: @meal.name)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def show
    authorize @meal
  end

  private

  def set_meal
    @meal = Meal.find(params[:id])
  end

  def meal_params
    params.require(:meal).permit(:name, :start_at, :end_at)
  end
end
