class ChangeReinvestmentPercentageNullInBacktests < ActiveRecord::Migration[8.0]
  def change
    change_column_null :backtests, :reinvestment_percentage, true
  end
end
