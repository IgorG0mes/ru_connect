class TicketPricesController < ApplicationController
  before_action :set_ticket_price, only: [:update]

  def index
    authorize TicketPrice
    TicketPrice.ensure_all!
    @ticket_prices = TicketPrice.order(:payable_type)
  end

  def update
    authorize @ticket_price
    if @ticket_price.update(ticket_price_params)
      redirect_to ticket_prices_path, notice: t("flash.ticket_prices.updated", type: @ticket_price.payable_type)
    else
      redirect_to ticket_prices_path, alert: t("flash.ticket_prices.invalid")
    end
  end

  private

  def set_ticket_price
    @ticket_price = TicketPrice.find(params[:id])
  end

  def ticket_price_params
    params.require(:ticket_price).permit(:price)
  end
end
