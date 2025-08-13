require "httparty"
require "json"

class NseHistoricalDataJob < ApplicationJob
  queue_as :default

  BASE_URL = "https://www.nseindia.com/api/historicalOR/generateSecurityWiseHistoricalData"
  HEADERS = {
    "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/122.0.0.0 Safari/537.36",
    "Accept" => "*/*",
    "Accept-Language" => "en-US,en;q=0.9"
  }

  BATCH_DURATION = 4.months
  START_DATE = 5.years.ago.to_date

  def perform(symbol)
    stock = Stock.find_or_create_by(ticker: symbol.upcase)

    fetch_symbol_name(stock) if stock.name.nil? || stock.listing_date.nil?
    return { fetched: true, notice: "Prices were present already" } if stock&.stock_prices.present?

    current_from = [ START_DATE, stock.listing_date.to_date ].max
    current_to = current_from + BATCH_DURATION

    loop do
      response = HTTParty.get(BASE_URL, query: {
        from: current_from.strftime("%d-%m-%Y"),
        to: current_to.strftime("%d-%m-%Y"),
        symbol:,
        type: "priceVolumeDeliverable",
        series: "EQ"
      }, headers: HEADERS)


      data = JSON.parse(response.body, symbolize_names: true)
      break unless data[:data].present?

      Rails.logger.info "\n📆 Fetching: #{current_from} → #{current_to} | Records: #{data[:data].size}"

      prices = extract_prices(data[:data], stock.id)
      save_prices(prices)

      break if data[:data].size < 70

      current_from = prices.last[:date] + 1.day
      current_to = current_from + BATCH_DURATION
    end
  rescue => e
    Rails.logger.error "NSE fetch failed for #{symbol}: #{e.message}"
  end

  private

  def extract_prices(data_rows, stock_id)
    data_rows.map do |values|
      begin
        {
          stock_id: stock_id,
          date: Date.parse(values[:mTIMESTAMP]),
          close_price: values[:CH_CLOSING_PRICE].to_f.round(2),
          open_price: values[:CH_OPENING_PRICE].to_f.round(2),
          high_price: values[:CH_TRADE_HIGH_PRICE].to_f.round(2),
          low_price: values[:CH_TRADE_LOW_PRICE].to_f.round(2),
          volume: values[:CH_TOT_TRADED_QTY].to_i,
          created_at: Time.current,
          updated_at: Time.current
        }
      rescue
        nil
      end
    end.compact
  end

  def save_prices(prices)
    return if prices.empty?
    StockPrice.upsert_all(prices, unique_by: [ :stock_id, :date ])
  end

  def fetch_symbol_name(stock)
    symbol = stock.ticker
    return unless symbol.present?

    record = SearchStockService.fetch_stock_search(symbol).find { |s| s.ticker == symbol }
    return unless record.present?

    stock.update_columns(name: record.name, listing_date: record.listing_date)
  end
end
