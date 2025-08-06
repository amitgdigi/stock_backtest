# == Schema Information
#
# Table name: backtests
#
#  id                      :bigint           not null, primary key
#  buy_dip_percentage      :decimal(5, 2)    not null
#  end_date                :date
#  investment_amount       :decimal(15, 2)   not null
#  maximum_buy_amount      :decimal(10, 2)
#  reinvestment_percentage :decimal(5, 2)
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
  after_create_commit :set_default_values

  validates :start_date, :investment_amount, :sell_profit_percentage, :buy_dip_percentage, presence: true
  validates :investment_amount, :sell_profit_percentage, :buy_dip_percentage, numericality: { greater_than: 0 }
  validates :end_date, comparison: { greater_than: :start_date }, if: -> { end_date.present? }

  def set_default_values
    self.buy_dip_percentage = 50.0 if buy_dip_percentage.nil?
    self.end_date = Date.today if end_date.nil?
    self.investment_amount = 10000 if investment_amount.nil?
    self.reinvestment_percentage = 50.0 if reinvestment_percentage.nil?
    self.sell_profit_percentage = 3.0 if sell_profit_percentage.nil?
  end
end
