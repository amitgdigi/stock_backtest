class AddTotalBoughtAmountForStock < ActiveRecord::Migration[8.0]
  def change
    add_column :ipo_stocks, :total_bought_amount_for_stock, :decimal, precision: 15, scale: 2
  end
end
