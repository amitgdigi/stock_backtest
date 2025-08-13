# == Schema Information
#
# Table name: stocks
#
#  id           :bigint           not null, primary key
#  listing_date :date
#  name         :string
#  ticker       :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_stocks_on_ticker  (ticker) UNIQUE
#
class Stock < ApplicationRecord
  has_many :stock_prices, dependent: :destroy
  has_many :backtests, dependent: :destroy
  has_and_belongs_to_many :multi_stocks
  validates :ticker, presence: true, uniqueness: true

  def display_name
    name.present? ? "#{ticker} - #{name}" : ticker
  end

  def serialize
    {
      id:,
      ticker:,
      name:,
      listing_date:
    }
  end
end
