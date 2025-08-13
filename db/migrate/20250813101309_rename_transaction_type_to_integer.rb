class RenameTransactionTypeToInteger < ActiveRecord::Migration[8.0]
  def up
    rename_column :transactions, :transaction_type, :kind
    change_column :transactions, :kind, :integer, default: 0, using: "kind::integer"
  end

  def down
    rename_column :transactions, :kind, :transaction_type
    change_column :transactions, :transaction_type, :string
  end
end
# say_with_time "Migrating without loading the model,\n As anonymous class" do
#   transaction_model = Class.new(ActiveRecord::Base) do
#     self.table_name = 'transactions'
#   end

#   transaction_model.find_each do |t|
#     t.update_column(:kind, t.transaction_type)
#   end
# end
