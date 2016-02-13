class ChangeRequestIndex < ActiveRecord::Migration
  def change
    change_column :qbwc_jobs, :request_index, :text
  end
end
