class IndexQbwcJobs < ActiveRecord::Migration
  def change
    add_index :qbwc_jobs, :name, unique: true
    add_index :qbwc_jobs, :company, length: 150
  end
end
