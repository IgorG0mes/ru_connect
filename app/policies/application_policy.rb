class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?   = permitted?(:index)
  def show?    = permitted?(:show)
  def new?     = permitted?(:new)
  def create?  = new?
  def edit?    = permitted?(:edit)
  def update?  = edit?
  def destroy? = permitted?(:destroy)

  class Scope
    def initialize(user, scope)
      @user  = user
      @scope = scope
    end

    def resolve
      raise NotImplementedError, "#{self.class} is missing a `resolve` method."
    end

    private

    attr_reader :user, :scope
  end

  private

  def permitted?(action)
    return true if admin?
    return false unless user&.role
    Permission.granted?(user.role, resource_name, action.to_s)
  end

  def resource_name
    self.class.name.delete_suffix("Policy")
  end

  def admin?          = user&.role&.name == "admin"
  def leader?         = user&.role&.name == "leader"
  def admin_or_leader? = admin? || leader?
end
