require "rails_helper"

RSpec.describe TicketPricesController, type: :request do
  let!(:student_price) { TicketPrice.find_or_create_by!(payable_type: "Student", price: 6.25) }

  describe "unauthenticated access" do
    it "redirects index to sign-in" do
      get ticket_prices_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "as admin" do
    include_context "with admin"

    it "lists the ticket prices" do
      get ticket_prices_path
      expect(response).to be_successful
    end

    it "updates a ticket price" do
      patch ticket_price_path(student_price), params: { ticket_price: { price: "7.00" } }
      expect(response).to redirect_to(ticket_prices_path)
      expect(student_price.reload.price).to eq(7.00)
    end
  end

  describe "as unauthorized user" do
    include_context "with unauthorized user"

    it "blocks update without permission" do
      patch ticket_price_path(student_price), params: { ticket_price: { price: "7.00" } }
      expect(response).to redirect_to(root_path)
      expect(student_price.reload.price).to eq(6.25)
    end
  end
end
