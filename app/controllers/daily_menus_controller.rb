class DailyMenusController < ApplicationController
  before_action :authenticate_user!, except: [:today]
  before_action :set_daily_menu, only: [:edit, :update, :destroy]

  def index
    per_page = 2
    @page = (params[:page] || 1).to_i

    all_dates = DailyMenu.where(date: Date.current..).distinct.order(date: :asc).pluck(:date)
    @total_pages = (all_dates.count / per_page.to_f).ceil.clamp(1, Float::INFINITY).to_i
    @page = @page.clamp(1, @total_pages)

    paginated_dates = all_dates.slice((@page - 1) * per_page, per_page) || []

    @menus_by_date = DailyMenu.includes(:meal)
                               .where(date: paginated_dates)
                               .order(date: :asc)
                               .group_by(&:date)
  end

  def new
    @daily_menu = DailyMenu.new(date: Date.current)
    @meals = Meal.all
  end

  def create
    @daily_menu = DailyMenu.new(daily_menu_params)

    if @daily_menu.save
      redirect_to daily_menus_path, notice: t("flash.daily_menus.created", date: l(@daily_menu.date))
    else
      @meals = Meal.all
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @meals = Meal.all
  end

  def destroy
    @daily_menu.destroy
    redirect_to daily_menus_path, notice: t("flash.daily_menus.deleted")
  end

  def update
    if @daily_menu.update(daily_menu_params)
      redirect_to daily_menus_path, notice: t("flash.daily_menus.updated")
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
      flash.now[:alert] = t("flash.daily_menus.no_meal")
    elsif @current_menu.nil? && (Date.current.saturday? || Date.current.sunday?)
      flash.now[:alert] = t("flash.daily_menus.closed_weekend")
    elsif Holidays.on(Date.current, :br).any?
      flash.now[:alert] = t("flash.daily_menus.closed_holiday")
    end
  end

  private

  def set_daily_menu
    @daily_menu = DailyMenu.find(params[:id])
  end

  def daily_menu_params
    params.require(:daily_menu).permit(
      :date, :meal_id,
      :animal_protein, :vegan_protein,
      :side_dish_one, :side_dish_two, :side_dish_three,
      :salad_one, :salad_two, :salad_three,
      :dessert_one, :dessert_two
    )
  end
end
