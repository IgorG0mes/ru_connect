class PermissionsController < ApplicationController
  def index
    authorize :permission
    @roles = Role.where.not(name: "admin").order(:name)
    @selected_role = params[:role_id] ? Role.find(params[:role_id]) : @roles.first
    @resources   = Permission.resources_and_actions
    @all_actions = Permission.all_actions
    @granted     = Permission.where(role: @selected_role).pluck(:resource, :action).to_set
  end

  def toggle
    authorize :permission
    role = Role.find(params[:role_id])
    perm = Permission.find_or_initialize_by(
      role: role,
      resource: params[:resource],
      action: params[:permission_action]
    )

    granted = if perm.persisted?
      perm.destroy!
      false
    else
      perm.save!
      true
    end

    render turbo_stream: turbo_stream.replace(
      "perm_#{role.id}_#{params[:resource]}_#{params[:permission_action]}",
      partial: "permissions/cell",
      locals: { role: role, resource: params[:resource], action: params[:permission_action], granted: granted }
    )
  end
end
