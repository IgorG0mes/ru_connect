class MealsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_meal, only: [ :show, :edit, :update ]

  def index
    @meals = Meal.all
  end

  def new
    @meal = Meal.new
  end

  def create
    @meal = Meal.new(meal_params)

    if @meal.save
      redirect_to meals_path, notice: "Refeição #{@meal.name} cadastrada com sucesso!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @meal.update(meal_params)
      redirect_to meals_path, notice: "Refeição #{@meal.name} atualizada com sucesso!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def show
  end


  private

  def set_meal
    @meal = Meal.find(params[:id])
  end

  def meal_params
    params.require(:meal).permit(:name, :start_at, :end_at)
  end
end
