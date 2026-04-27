require "rails_helper"

RSpec.describe DailyMenusController, type: :request do
  def create_meal(name: "Almoco_#{SecureRandom.hex(3)}")
    Meal.create!(name: name, start_at: "11:00", end_at: "14:00")
  end

  def valid_menu_params(meal, overrides = {})
    {
      date:           Date.current + 1.day,
      meal_id:        meal.id,
      animal_protein: "Frango",
      vegan_protein:  "Tofu",
      side_dish_one:  "Arroz",
      salad_one:      "Alface",
      dessert_one:    "Fruta"
    }.merge(overrides)
  end

  def create_menu(meal, overrides = {})
    DailyMenu.create!(valid_menu_params(meal, overrides))
  end

  describe "GET /menu (today) - public" do
    context "when there is no current meal" do
      it "returns 200 without login" do
        get public_menu_path
        expect(response).to be_successful
      end
    end

    context "when there is a current meal with a menu for today" do
      it "renders the menu" do
        meal = Meal.create!(
          name:     "Almoco_now",
          start_at: (Time.current - 1.hour).strftime("%H:%M"),
          end_at:   (Time.current + 1.hour).strftime("%H:%M")
        )
        DailyMenu.create!(
          date: Date.current, meal: meal,
          animal_protein: "Carne", vegan_protein: "Grao",
          side_dish_one: "Arroz", salad_one: "Alface", dessert_one: "Laranja"
        )
        get public_menu_path
        expect(response).to be_successful
        expect(response.body).to include("Carne")
      end
    end
  end

  describe "unauthenticated access to admin routes" do
    it "redirects index to sign-in" do
      get daily_menus_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects new to sign-in" do
      get new_daily_menu_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "as admin" do
    include_context "with admin"

    describe "GET /daily_menus (index)" do
      it "returns 200" do
        get daily_menus_path
        expect(response).to be_successful
      end

      it "paginates by date" do
        get daily_menus_path, params: { page: 1 }
        expect(response).to be_successful
      end
    end

    describe "GET /daily_menus/new" do
      it "returns 200" do
        get new_daily_menu_path
        expect(response).to be_successful
      end
    end

    describe "POST /daily_menus (create)" do
      context "with valid params" do
        it "creates menu and redirects to daily_menus_path" do
          meal = create_meal
          expect {
            post daily_menus_path, params: { daily_menu: valid_menu_params(meal) }
          }.to change(DailyMenu, :count).by(1)
          expect(response).to redirect_to(daily_menus_path)
        end
      end

      context "with invalid params" do
        it "renders :new with 422" do
          post daily_menus_path, params: { daily_menu: { date: "" } }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    describe "GET /daily_menus/:id/edit" do
      it "returns 200" do
        menu = create_menu(create_meal)
        get edit_daily_menu_path(menu)
        expect(response).to be_successful
      end
    end

    describe "PATCH /daily_menus/:id (update)" do
      context "with valid params" do
        it "updates and redirects to daily_menus_path" do
          menu = create_menu(create_meal)
          patch daily_menu_path(menu), params: { daily_menu: { animal_protein: "Peixe" } }
          expect(response).to redirect_to(daily_menus_path)
          expect(menu.reload.animal_protein).to eq("Peixe")
        end
      end

      context "with invalid params" do
        it "renders :edit with 422" do
          menu = create_menu(create_meal)
          patch daily_menu_path(menu), params: { daily_menu: { animal_protein: "" } }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    describe "DELETE /daily_menus/:id (destroy)" do
      it "destroys menu and redirects to daily_menus_path" do
        menu = create_menu(create_meal)
        expect {
          delete daily_menu_path(menu)
        }.to change(DailyMenu, :count).by(-1)
        expect(response).to redirect_to(daily_menus_path)
      end
    end
  end

  describe "as non-admin without permission" do
    include_context "with unauthorized user"

    it "redirects index to root" do
      get daily_menus_path
      expect(response).to redirect_to(root_path)
    end

    it "redirects new to root" do
      get new_daily_menu_path
      expect(response).to redirect_to(root_path)
    end

    it "redirects create to root" do
      post daily_menus_path, params: { daily_menu: valid_menu_params(create_meal) }
      expect(response).to redirect_to(root_path)
    end

    it "redirects edit to root" do
      menu = create_menu(create_meal)
      get edit_daily_menu_path(menu)
      expect(response).to redirect_to(root_path)
    end

    it "redirects update to root" do
      menu = create_menu(create_meal)
      patch daily_menu_path(menu), params: { daily_menu: { animal_protein: "X" } }
      expect(response).to redirect_to(root_path)
    end

    it "redirects destroy to root" do
      menu = create_menu(create_meal)
      delete daily_menu_path(menu)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "as non-admin with granted permissions" do
    include_context "with unauthorized user"

    before do
      grant(plain_role, "DailyMenu", "index")
      grant(plain_role, "DailyMenu", "new")
      grant(plain_role, "DailyMenu", "edit")
      grant(plain_role, "DailyMenu", "destroy")
    end

    it "can access index" do
      get daily_menus_path
      expect(response).to be_successful
    end

    it "can access new" do
      get new_daily_menu_path
      expect(response).to be_successful
    end

    it "can create menu" do
      meal = create_meal
      expect {
        post daily_menus_path, params: { daily_menu: valid_menu_params(meal) }
      }.to change(DailyMenu, :count).by(1)
      expect(response).to redirect_to(daily_menus_path)
    end

    it "can access edit" do
      menu = create_menu(create_meal)
      get edit_daily_menu_path(menu)
      expect(response).to be_successful
    end

    it "can update menu" do
      menu = create_menu(create_meal)
      patch daily_menu_path(menu), params: { daily_menu: { animal_protein: "Atum" } }
      expect(response).to redirect_to(daily_menus_path)
    end

    it "can destroy menu" do
      menu = create_menu(create_meal)
      expect {
        delete daily_menu_path(menu)
      }.to change(DailyMenu, :count).by(-1)
      expect(response).to redirect_to(daily_menus_path)
    end
  end
end
