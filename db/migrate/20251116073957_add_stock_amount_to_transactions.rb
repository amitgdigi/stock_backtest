class AddStockAmountToTransactions < ActiveRecord::Migration[8.0]
  def change
    add_column :transactions, :stock_amount, :decimal, precision: 15, scale: 2
  end
end
