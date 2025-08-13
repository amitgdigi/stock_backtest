class CreateMultiStocks < ActiveRecord::Migration[8.0]
  def change
    create_table :multi_stocks do |t|
      t.date :start_date, null: false
      t.date :end_date
      t.decimal :investment_amount, null: false, precision: 15, scale: 2
      t.decimal :maximum_buy_amount, precision: 10, scale: 2
      t.decimal :sell_profit_percentage, null: false, precision: 5, scale: 2
      t.decimal :buy_dip_percentage, null: false, precision: 5, scale: 2
      t.decimal :reinvestment_percentage, precision: 5, scale: 2
      t.decimal :total_amount, precision: 15, scale: 2
      t.string :status, default: 'pending'

      t.timestamps
    end
  end
end
