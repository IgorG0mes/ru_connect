class DailyMenusController < ApplicationController
  before_action :authenticate_user!, except: [:today]
  before_action :set_daily_menu, only: [:edit, :update]

  def index
    @daily_menus = DailyMenu.includes(:meal).order(date: :asc)
  end

  def new
    @daily_menu = DailyMenu.new
    @meals = Meal.all
  end

  def create
    @daily_menu = DailyMenu.new(daily_menu_params)

    if @daily_menu.save
      redirect_to daily_menus_path, notice: "Cardápio para #{Date.parse(@daily_menu.date.to_s).strftime('%d/%m/%Y')} cadastrado com sucesso."
    else
      @meals = Meal.all
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @meals = Meal.all
  end

  def update
    if @daily_menu.update(daily_menu_params)
      redirect_to daily_menus_path, notice: "Cardápio atualizado com sucesso!"
    else
      @meals = Meal.all
      render :edit, status: :unprocessable_entity
    end
  end

  def today
    current_meal = Meal.find_current
    @current_menu = DailyMenu.includes(:meal)
                             .find_by(date: Date.current, meal: current_meal)

    if current_meal.nil?
      flash.now[:alert] = "Não há refeição disponível no momento."
    elsif @current_menu.nil? && (Date.current.saturday? || Date.current.sunday?)
      flash.now[:alert] = "O RU está fechado aos finais de semana."
    elsif Holidays.on(Date.current, :br).any?
      flash.now[:alert] = "O RU está fechado em feriados."
    end
  end

  private

  def set_daily_menu
    @daily_menu = DailyMenu.find(params[:id])
  end

  def daily_menu_params
    params.require(:daily_menu).permit(
      :date,
      :meal_id,
      :main_dish,
      :side_dish,
      :salad,
      :dessert
    )
  end
end
