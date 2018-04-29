class AddMacIndexToNics < ActiveRecord::Migration[5.1]
  def change
    add_index :nics, :mac
  end
end
