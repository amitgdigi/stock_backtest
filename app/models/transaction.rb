# == Schema Information
#
# Table name: transactions
#
#  id               :bigint           not null, primary key
#  amount           :decimal(15, 2)   not null
#  date             :date             not null
#  price            :decimal(10, 2)   not null
#  quantity         :integer          not null
#  transaction_type :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  backtest_id      :bigint           not null
#
# Indexes
#
#  index_transactions_on_backtest_id  (backtest_id)
#
# Foreign Keys
#
#  fk_rails_...  (backtest_id => backtests.id)
#
class Transaction < ApplicationRecord
  belongs_to :backtest
  validates :transaction_type, :date, :price, :quantity, :amount, presence: true
  validates :transaction_type, inclusion: { in: %w[buy sell] }

  scope :sold, -> { where(transaction_type: "sell") }
  scope :unsold_stocks, -> {
    last_sell_record = where(transaction_type: "sell").order(created_at: :desc).first
    if last_sell_record.present?
      where("created_at > ?", last_sell_record.created_at)
    else
      all
    end
   }
end
