class CreateQbwcSessions < ActiveRecord::Migration
  def change
    create_table :qbwc_sessions do |t|
      t.string :ticket
      t.string :user
      t.string :company, :limit => 1000
      t.integer :progress, :null => false, :default => 0
      t.string :current_job
      t.string :iterator_id
      t.string :error, :limit => 1000
      t.string :pending_jobs, :limit => 1000, :null => false, :default => ''

      t.timestamps
    end
  end
end
