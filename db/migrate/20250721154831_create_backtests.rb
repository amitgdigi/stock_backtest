class CreateBacktests < ActiveRecord::Migration[8.0]
  def change
    create_table :backtests do |t|
      t.references :stock, null: false, foreign_key: true
      t.date :start_date, null: false
      t.date :end_date
      t.decimal :investment_amount, null: false, precision: 15, scale: 2
      t.decimal :sell_profit_percentage, null: false, precision: 5, scale: 2
      t.decimal :buy_dip_percentage, null: false, precision: 5, scale: 2
      t.decimal :reinvestment_percentage, null: false, precision: 5, scale: 2
      t.string :status, default: 'pending'

      t.timestamps
    end
  end
end
