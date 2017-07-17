class ChangeRequestIndex < ActiveRecord::Migration[5.1]
  def change
    change_column :qbwc_jobs, :request_index, :text, null: true, default: nil
  end
end
