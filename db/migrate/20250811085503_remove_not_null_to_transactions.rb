class RemoveNotNullToTransactions < ActiveRecord::Migration[8.0]
  def up
    change_column_null :transactions, :backtest_id, true
  end

  def down
    Transaction.where(backtest_id: nil).destroy_all
    change_column_null :transactions, :backtest_id, false
  end
end
