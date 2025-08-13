class AddStockIdToTransactions < ActiveRecord::Migration[8.0]
  def change
    add_reference :transactions, :stock, foreign_key: true
  end
end
