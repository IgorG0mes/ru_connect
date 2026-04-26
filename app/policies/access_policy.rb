class AccessPolicy < ApplicationPolicy
  def index? = permitted?(:index)
end
