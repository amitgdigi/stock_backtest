class CreateStocks < ActiveRecord::Migration[8.0]
  def change
    create_table :stocks do |t|
      t.string :name
      t.string :ticker

      t.timestamps
    end
    add_index :stocks, :ticker, unique: true
  end
end
