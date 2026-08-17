module TicketWallet
  extend ActiveSupport::Concern

  included do
    validates :ticket_balance, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  end

  def consume_ticket!
    with_lock do
      return false if ticket_balance < 1

      update!(ticket_balance: ticket_balance - 1)
    end
    true
  end

  def credit_tickets!(quantity)
    with_lock do
      update!(ticket_balance: ticket_balance + quantity)
    end
  end
end
