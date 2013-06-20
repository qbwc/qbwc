class CreateQbwcJobs < ActiveRecord::Migration
  def change
    create_table :qbwc_jobs do |t|
      t.string :name
      t.string :company, :limit => 1000
      t.boolean :enabled, :null => false, :default => false
      t.integer :next_request, :null => false, :default => 0

      t.timestamps
    end
  end
end
