class CreateQbwcSessions < ActiveRecord::Migration[5.0]
  def change
    create_table :qbwc_sessions, :force => true do |t|
      t.string :ticket
      t.string :user
      t.string :company, :limit => 1000
      t.integer :progress, :null => false, :default => 0
      t.string :current_job
      t.string :iterator_id
      t.string :error, :limit => 1000
      t.text :pending_jobs, :null => false, :default => ''

      t.timestamps :null => false
    end
  end
end
