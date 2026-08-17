class Permission < ApplicationRecord
  belongs_to :role

  validates :resource, :action, presence: true
  validates :action, uniqueness: { scope: [:role_id, :resource] }

  STANDARD_ACTIONS = %w[index show new edit destroy].freeze
  EXCLUDED_POLICIES = %w[ApplicationPolicy PermissionPolicy].freeze

  def self.resources_and_actions
    load_policies!

    ApplicationPolicy.subclasses
      .reject { |klass| EXCLUDED_POLICIES.include?(klass.name) }
      .sort_by(&:name)
      .each_with_object({}) do |klass, hash|
        resource = klass.name.delete_suffix("Policy")
        custom   = klass.public_instance_methods(false)
                        .map(&:to_s)
                        .select { |m| m.end_with?("?") }
                        .map    { |m| m.delete_suffix("?") }
        hash[resource] = (STANDARD_ACTIONS + custom).uniq
      end
  end

  def self.all_actions
    resources_and_actions.values.flatten.uniq
  end

  def self.granted?(role, resource, action)
    return false unless role
    Rails.cache.fetch("perm/#{role.id}/#{resource}/#{action}", expires_in: 5.minutes) do
      where(role: role, resource: resource, action: action.to_s).exists?
    end
  end

  after_commit :clear_cache

  private_class_method def self.load_policies!
    return if Rails.configuration.eager_load
    Dir.glob(Rails.root.join("app/policies/*_policy.rb")).each { |f| require_dependency f }
  end

  private

  def clear_cache
    Rails.cache.delete("perm/#{role_id}/#{resource}/#{action}")
  end
end
