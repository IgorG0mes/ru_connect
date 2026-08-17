class Payment < ApplicationRecord
  belongs_to :payable, polymorphic: true

  MAX_QUANTITY = 50

  enum :status, { pending: 0, approved: 1, rejected: 2, cancelled: 3, refunded: 4 }

  validates :external_reference, presence: true, uniqueness: true
  validates :quantity, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 1,
    less_than_or_equal_to: MAX_QUANTITY
  }
  validates :amount, numericality: { greater_than: 0 }

  def confirm_and_credit!(mp_amount:, mp_payment_id:)
    return false if approved?

    if mp_amount.to_d != amount
      raise ArgumentError, "valor divergente: esperado #{amount}, recebido #{mp_amount}"
    end

    transaction do
      payable.credit_tickets!(quantity)
      update!(status: :approved, mp_payment_id: mp_payment_id)
    end

    true
  end
end
