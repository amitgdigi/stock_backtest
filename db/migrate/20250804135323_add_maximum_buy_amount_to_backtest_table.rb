class AddMaximumBuyAmountToBacktestTable < ActiveRecord::Migration[8.0]
  def change
    add_column :backtests, :maximum_buy_amount, :decimal, precision: 10, scale: 2
  end
end
