class AddTotalAmountToTransactions < ActiveRecord::Migration[8.0]
  def change
    add_column :transactions, :total_amount, :decimal, precision: 15, scale: 2
  end
end
