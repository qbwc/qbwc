class CreateQbwcJobs < ActiveRecord::Migration
  def change
    create_table :qbwc_jobs do |t|
      t.string :name
      t.string :company, :limit => 1000
      t.string :worker_class, :limit => 100
      t.boolean :enabled, :null => false, :default => false
      t.integer :request_index, :null => false, :default => 0
      t.text :requests
      t.text :data
      t.boolean :worker_requests_called
      t.timestamps
    end
  end
end
