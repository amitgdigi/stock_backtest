class AddMultiStockToTransactions < ActiveRecord::Migration[8.0]
  def change
    add_reference :transactions, :multi_stock, foreign_key: true
  end
end
