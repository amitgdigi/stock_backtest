# == Schema Information
#
# Table name: stock_prices
#
#  id          :bigint           not null, primary key
#  close_price :decimal(10, 2)   not null
#  date        :date             not null
#  high_price  :decimal(10, 2)
#  low_price   :decimal(10, 2)
#  open_price  :decimal(10, 2)
#  volume      :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  stock_id    :bigint           not null
#
# Indexes
#
#  index_stock_prices_on_stock_id           (stock_id)
#  index_stock_prices_on_stock_id_and_date  (stock_id,date) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (stock_id => stocks.id)
#
class StockPrice < ApplicationRecord
  belongs_to :stock
  validates :date, :close_price, presence: true
  validates :date, uniqueness: { scope: :stock_id }
end
