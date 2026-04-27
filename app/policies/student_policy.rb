class StudentPolicy < ApplicationPolicy
  def regenerate_qr? = permitted?(:regenerate_qr)
end
