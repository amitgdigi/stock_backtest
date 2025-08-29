# == Schema Information
#
# Table name: transactions
#
#  id             :bigint           not null, primary key
#  amount         :decimal(15, 2)   not null
#  date           :date             not null
#  kind           :integer          default("buy"), not null
#  open           :boolean          default(TRUE)
#  price          :decimal(10, 2)   not null
#  quantity       :integer          not null
#  total_amount   :decimal(15, 2)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  backtest_id    :bigint
#  multi_stock_id :bigint
#  stock_id       :bigint
#
# Indexes
#
#  index_transactions_on_backtest_id     (backtest_id)
#  index_transactions_on_multi_stock_id  (multi_stock_id)
#  index_transactions_on_stock_id        (stock_id)
#
# Foreign Keys
#
#  fk_rails_...  (backtest_id => backtests.id)
#  fk_rails_...  (multi_stock_id => multi_stocks.id)
#  fk_rails_...  (stock_id => stocks.id)
#
class Transaction < ApplicationRecord
  attribute :kind, :integer
  enum :kind, { buy: 0, sell: 1 }, default: :buy

  belongs_to :backtest, optional: true
  belongs_to :multi_stock, optional: true
  belongs_to :stock, optional: true

  validates :kind, :date, :price, :quantity, :amount, presence: true
  validates :kind, inclusion: { in: %w[buy sell] }

  scope :sold, ->(stock_id: nil, multi_stock_id: nil, backtest_id: nil) {
    query = where(kind: "sell")
    query = query.where(stock_id:) if stock_id.present?
    query = query.where(multi_stock_id:) if multi_stock_id.present?
    query = query.where(backtest_id:) if backtest_id.present?
    query
  }

  scope :unsold_stocks, ->(stock_id: nil) {
    base = stock_id.present? ? where(stock_id:) : all
    last_sell_at = base.sell.maximum(:created_at)

    if last_sell_at.present?
      base.where("created_at > ?", last_sell_at)
    else
      base
    end
  }

  def collect_unsold_between(include_self: false)
    last_sell = self.class
                   .where(multi_stock_id: multi_stock_id, stock_id: stock_id, kind: "sell")
                   .where("created_at < ?", created_at)
                   .order(created_at: :desc)
                   .first

    scope = self.class.where(multi_stock_id:, stock_id:)
    if last_sell.present?
      scope = scope.where("created_at > ? AND created_at < ?", last_sell.created_at, created_at)
    else
      scope = scope.where("created_at < ?", created_at)
    end
    scope = scope.to_a
    scope << self if include_self && self.buy?
    scope
  end

  def serialize
    { id:,
      backtest_id:,
      type: kind,
      date:,
      price:,
      quantity:,
      amount:,
      open:,
      multi_stock_id:,
      stock_id:,
      stock_name: stock&.name,
      symbol: stock&.ticker,
      remains: total_amount
    }
  end
end
