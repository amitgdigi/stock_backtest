class CreateIpoStocksAndJoinTable < ActiveRecord::Migration[8.0]
  def change
    create_table :ipo_stocks do |t|
      t.date :start_date, null: false
      t.date :end_date
      t.decimal :investment_amount, precision: 15, scale: 2, null: false
      t.decimal :maximum_buy_amount, precision: 10, scale: 2
      t.decimal :sell_profit_percentage, precision: 5, scale: 2, null: false
      t.decimal :first_buy_percentage, precision: 5, scale: 2, null: false
      t.decimal :buy_dip_percentage, precision: 5, scale: 2, null: false
      t.decimal :reinvestment_percentage, precision: 5, scale: 2
      t.decimal :total_amount, precision: 15, scale: 2
      t.string :status, default: "pending"
      t.timestamps
    end

    create_table :ipo_stocks_stocks, id: false do |t|
      t.bigint :ipo_stock_id, null: false
      t.bigint :stock_id, null: false
    end

    add_reference :transactions, :ipo_stock, foreign_key: true

    add_index :ipo_stocks_stocks, [:ipo_stock_id, :stock_id], unique: true, name: "index_ipo_stocks_stocks_on_ipo_stock_id_and_stock_id"
    add_index :ipo_stocks_stocks, [:stock_id, :ipo_stock_id], name: "index_ipo_stocks_stocks_on_stock_id_and_ipo_stock_id"
  end
end
