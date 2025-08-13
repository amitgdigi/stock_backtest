class CreateJoinTableMultiStocksStocks < ActiveRecord::Migration[8.0]
  def change
    create_join_table :multi_stocks, :stocks do |t|
      t.index [ :multi_stock_id, :stock_id ], unique: true
      t.index [ :stock_id, :multi_stock_id ]
    end
  end
end
