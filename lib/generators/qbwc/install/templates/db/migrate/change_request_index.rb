class ChangeRequestIndex < ActiveRecord::Migration
  def change
    change_column :qbwc_jobs, :request_index, :text, null: true, default: nil
  end
end
