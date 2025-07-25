require "httparty"
require "json"

class AlphaVantageService
  BASE_URL = "https://www.alphavantage.co/query"
  API_KEY = ENV.fetch("STOCK_API_KEY")
  # LATEST_OR_FULL = "compact"
  LATEST_OR_FULL = "full"

  def self.fetch_daily_prices(ticker, start_date, end_date)
    stock = Stock.find_by(ticker: ticker.upcase)
    unless stock
      stock = Stock.create(ticker: ticker.upcase)
      response = HTTParty.get(BASE_URL, query: {
        function: "TIME_SERIES_DAILY",
        symbol: ticker.upcase,
        outputsize: LATEST_OR_FULL,
        apikey: API_KEY
      })

      data = JSON.parse(response.body, symbolize_names: true)

      return { error: data[:'Error Message'] || data[:'Information'] || "No data returned" } unless data[:'Time Series (Daily)']

      prices = data[:'Time Series (Daily)'].map do |date_str, values|
        date = Date.parse("#{date_str}")
        {
          stock_id: stock.id,
          date: date,
          close_price: values[:'4. close'].to_f.round(2),
          open_price: values[:'1. open'].to_f.round(2),
          high_price: values[:'2. high'].to_f.round(2),
          low_price: values[:'3. low'].to_f.round(2),
          volume: values[:'5. volume'].to_i,
          created_at: Time.now,
          updated_at: Time.now
        }
      end.compact

      # Bulk insert
      StockPrice.transaction do
        StockPrice.upsert_all(prices, unique_by: [ :stock_id, :date ]) if prices.any?
      end
    end
    prices ||= stock.stock_prices

    { prices:, stock: }
  rescue HTTParty::Error, StandardError => e
    { error: "Failed to fetch prices: #{e.message}" }
  end
end
