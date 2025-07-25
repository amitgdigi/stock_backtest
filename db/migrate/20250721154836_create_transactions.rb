class CreateTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :transactions do |t|
      t.references :backtest, null: false, foreign_key: true
      t.string :transaction_type, null: false
      t.date :date, null: false
      t.decimal :price, null: false, precision: 10, scale: 2
      t.integer :quantity, null: false
      t.decimal :amount, null: false, precision: 15, scale: 2

      t.timestamps
    end
  end
end
