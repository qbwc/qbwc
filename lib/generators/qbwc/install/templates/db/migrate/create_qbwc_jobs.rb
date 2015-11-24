class CreateQbwcJobs < ActiveRecord::Migration
  def change
    create_table :qbwc_jobs, :force => true do |t|
      t.string :name
      t.string :company, :limit => 1000
      t.string :worker_class, :limit => 100
      t.boolean :enabled, :null => false, :default => false
      t.text :request_index
      t.text :requests
      t.boolean :requests_provided_when_job_added, :null => false, :default => false
      t.text :data
      t.timestamps :null => false
    end
    add_index :qbwc_jobs, :name, unique: true
    add_index :qbwc_jobs, :company
  end
end
