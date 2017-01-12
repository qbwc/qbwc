class SessionRequestsRequestIndexColumns < ActiveRecord::Migration
  def change
    add_column :qbwc_sessions, :current_request_index, :integer, null: false, default: 0
    add_column :qbwc_sessions, :requests, :text, null: true, default: nil

    add_column :qbwc_jobs, :default_requests, :text, null: true, default: nil

    remove_column :qbwc_jobs, :request_index, :text
    remove_column :qbwc_jobs, :requests, :text
    remove_column :qbwc_jobs, :requests_provided_when_job_added, :boolean
  end
end
