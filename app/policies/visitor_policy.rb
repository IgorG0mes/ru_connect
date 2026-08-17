class VisitorPolicy < ApplicationPolicy
  def regenerate_qr? = permitted?(:regenerate_qr)
  def send_qr_email? = permitted?(:send_qr_email)
end
