# == Schema Information
#
# Table name: backtests
#
#  id                      :bigint           not null, primary key
#  buy_dip_percentage      :decimal(5, 2)    not null
#  end_date                :date
#  investment_amount       :decimal(15, 2)   not null
#  reinvestment_percentage :decimal(5, 2)    not null
#  sell_profit_percentage  :decimal(5, 2)    not null
#  start_date              :date             not null
#  status                  :string           default("pending")
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  stock_id                :bigint           not null
#
# Indexes
#
#  index_backtests_on_stock_id  (stock_id)
#
# Foreign Keys
#
#  fk_rails_...  (stock_id => stocks.id)
#
class Backtest < ApplicationRecord
  belongs_to :stock
  has_many :transactions, dependent: :destroy
  validates :start_date, :investment_amount, :sell_profit_percentage, :buy_dip_percentage, :reinvestment_percentage, presence: true
  validates :investment_amount, :sell_profit_percentage, :buy_dip_percentage, :reinvestment_percentage, numericality: { greater_than: 0 }
  validates :reinvestment_percentage, numericality: { less_than_or_equal_to: 100 }
  validates :end_date, comparison: { greater_than: :start_date }, if: -> { end_date.present? }
end
