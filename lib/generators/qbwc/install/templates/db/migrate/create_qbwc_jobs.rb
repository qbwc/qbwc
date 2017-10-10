class CreateQbwcJobs < ActiveRecord::Migration[5.0]
  def change
    create_table :qbwc_jobs, :force => true do |t|
      t.string :name
      t.string :company, :limit => 1000
      t.string :worker_class, :limit => 100
      t.boolean :enabled, :null => false, :default => false
      t.integer :request_index, :null => false, :default => 0
      t.text :requests
      t.boolean :requests_provided_when_job_added, :null => false, :default => false
      t.text :data
      t.timestamps :null => false
    end
  end
end
