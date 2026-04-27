require "rails_helper"

RSpec.describe MealsController, type: :request do
  def valid_meal_params(overrides = {})
    { name: "Almoco_#{SecureRandom.hex(3)}", start_at: "11:00", end_at: "14:00" }.merge(overrides)
  end

  def create_meal(overrides = {})
    Meal.create!(valid_meal_params(overrides))
  end

  describe "unauthenticated access" do
    it "redirects index to sign-in" do
      get meals_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "as admin" do
    include_context "with admin"

    describe "GET /meals (index)" do
      it "returns 200" do
        get meals_path
        expect(response).to be_successful
      end

      it "lists existing meals" do
        meal = create_meal
        get meals_path
        expect(response.body).to include(meal.name)
      end
    end

    describe "GET /meals/new" do
      it "returns 200" do
        get new_meal_path
        expect(response).to be_successful
      end
    end

    describe "POST /meals (create)" do
      context "with valid params" do
        it "creates meal and redirects to meals_path" do
          expect {
            post meals_path, params: { meal: valid_meal_params }
          }.to change(Meal, :count).by(1)
          expect(response).to redirect_to(meals_path)
        end
      end

      context "with invalid params" do
        it "renders :new with 422" do
          post meals_path, params: { meal: { name: "" } }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    describe "GET /meals/:id (show)" do
      it "returns 200" do
        meal = create_meal
        get meal_path(meal)
        expect(response).to be_successful
      end
    end

    describe "GET /meals/:id/edit" do
      it "returns 200" do
        meal = create_meal
        get edit_meal_path(meal)
        expect(response).to be_successful
      end
    end

    describe "PATCH /meals/:id (update)" do
      context "with valid params" do
        it "updates and redirects to meals_path" do
          meal = create_meal
          patch meal_path(meal), params: { meal: { name: "Jantar" } }
          expect(response).to redirect_to(meals_path)
          expect(meal.reload.name).to eq("Jantar")
        end
      end

      context "with invalid params" do
        it "renders :edit with 422" do
          meal = create_meal
          patch meal_path(meal), params: { meal: { name: "" } }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  describe "as non-admin without permission" do
    include_context "with unauthorized user"

    it "redirects index to root"  do
      get meals_path
      expect(response).to redirect_to(root_path)
    end

    it "redirects new to root" do
      get new_meal_path
      expect(response).to redirect_to(root_path)
    end

    it "redirects create to root" do
      post meals_path, params: { meal: valid_meal_params }
      expect(response).to redirect_to(root_path)
    end

    it "redirects show to root" do
      meal = create_meal
      get meal_path(meal)
      expect(response).to redirect_to(root_path)
    end

    it "redirects edit to root" do
      meal = create_meal
      get edit_meal_path(meal)
      expect(response).to redirect_to(root_path)
    end

    it "redirects update to root" do
      meal = create_meal
      patch meal_path(meal), params: { meal: { name: "X" } }
      expect(response).to redirect_to(root_path)
    end
  end

  describe "as non-admin with granted permissions" do
    include_context "with unauthorized user"

    before do
      grant(plain_role, "Meal", "index")
      grant(plain_role, "Meal", "show")
      grant(plain_role, "Meal", "new")
      grant(plain_role, "Meal", "edit")
    end

    it "can access index" do
      get meals_path
      expect(response).to be_successful
    end

    it "can access new" do
      get new_meal_path
      expect(response).to be_successful
    end

    it "can create meal" do
      expect {
        post meals_path, params: { meal: valid_meal_params }
      }.to change(Meal, :count).by(1)
      expect(response).to redirect_to(meals_path)
    end

    it "can access show" do
      meal = create_meal
      get meal_path(meal)
      expect(response).to be_successful
    end

    it "can access edit" do
      meal = create_meal
      get edit_meal_path(meal)
      expect(response).to be_successful
    end

    it "can update meal" do
      meal = create_meal
      patch meal_path(meal), params: { meal: { name: "Café da Tarde" } }
      expect(response).to redirect_to(meals_path)
    end
  end
end
