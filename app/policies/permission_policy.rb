class PermissionPolicy < ApplicationPolicy
  def index?  = admin?
  def toggle? = admin?
end
