require "rails_helper"

RSpec.describe TicketPrice, type: :model do
  let!(:student_price) { TicketPrice.find_or_create_by!(payable_type: "Student", price: 6.25) }
  let!(:visitor_price) { TicketPrice.find_or_create_by!(payable_type: "Visitor", price: 12.50) }
  describe "validations" do
    it "is valid with a known type and positive price" do
      expect(student_price).to be_valid
    end

    it "rejects an unknown payable_type" do
      expect(TicketPrice.new(payable_type: "Ghost", price: 1)).not_to be_valid
    end

    it "rejects a non-positive price" do
      expect(TicketPrice.new(payable_type: "Visitor", price: 0)).not_to be_valid
    end

    it "enforces uniqueness of payable_type" do
      TicketPrice.find_or_create_by!(payable_type: "Student", price: 6.25)
      dup = TicketPrice.new(payable_type: "Student", price: 7.00)
      expect(dup).not_to be_valid
    end
  end

  describe ".price_for" do
    it "returns the price for a type" do
      expect(visitor_price.price).to eq(12.50)
    end

    it "returns nil when there is no price for the type" do
      TicketPrice.where(payable_type: "Student").delete_all
      expect(TicketPrice.price_for("Student")).to be_nil
    end
  end
end
