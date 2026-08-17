class TicketPrice < ApplicationRecord
  PAYABLE_TYPES = %w[Student Visitor].freeze
  DEFAULT_PRICES = { "Student" => 6.50, "Visitor" => 12.50 }.freeze

  validates :payable_type, presence: true, uniqueness: true, inclusion: { in: PAYABLE_TYPES }
  validates :price, numericality: { greater_than: 0 }

  def self.price_for(payable_type)
    find_by(payable_type: payable_type.to_s)&.price
  end

  def self.ensure_all!
    PAYABLE_TYPES.each do |type|
      find_or_create_by!(payable_type: type) { |tp| tp.price = DEFAULT_PRICES.fetch(type, 1) }
    end
  end
end
