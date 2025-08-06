class ChangeReinvestmentPercentageNullInBacktests < ActiveRecord::Migration[8.0]
  def up
    change_column_null :backtests, :reinvestment_percentage, true
  end

  def down
    Backtest.where(reinvestment_percentage: nil).update_all(reinvestment_percentage: 0.0)

    change_column_null :backtests, :reinvestment_percentage, false
  end
end
