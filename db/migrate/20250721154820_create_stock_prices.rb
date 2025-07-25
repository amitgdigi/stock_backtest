class CreateStockPrices < ActiveRecord::Migration[8.0]
  def change
    create_table :stock_prices do |t|
      t.references :stock, null: false, foreign_key: true
      t.date :date, null: false
      t.decimal :open_price, precision: 10, scale: 2
      t.decimal :close_price, null: false, precision: 10, scale: 2
      t.decimal :high_price, precision: 10, scale: 2
      t.decimal :low_price, precision: 10, scale: 2
      t.integer :volume

      t.timestamps
    end
    add_index :stock_prices, [ :stock_id, :date ], unique: true
  end
end
