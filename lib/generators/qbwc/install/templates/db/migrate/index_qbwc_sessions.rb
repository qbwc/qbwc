class IndexQbwcSessions < ActiveRecord::Migration
  def change
    add_index :qbwc_sessions, :ticket, unique: true
  end
end
