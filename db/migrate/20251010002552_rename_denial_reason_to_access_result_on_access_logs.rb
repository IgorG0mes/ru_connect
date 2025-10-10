class RenameDenialReasonToAccessResultOnAccessLogs < ActiveRecord::Migration[7.1]
  def change
    rename_column :access_logs, :denial_reason, :access_result
  end
end
