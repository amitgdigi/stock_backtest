class AddOpenToTransactions < ActiveRecord::Migration[8.0]
  def change
    add_column :transactions, :open, :boolean, default: true
  end
end
