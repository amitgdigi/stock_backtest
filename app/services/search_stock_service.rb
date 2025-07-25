require "httparty"
require "json"

class SearchStockService
  BASE_URL = "https://www.alphavantage.co/query"
  API_KEY = ENV.fetch("STOCK_API_KEY")

  def self.fetch_stock_search(query)
    response = HTTParty.get(BASE_URL, query: {
      function: "SYMBOL_SEARCH",
      keywords: query,
      apikey: API_KEY
    })

    data = JSON.parse(response.body, symbolize_names: true)
    return [] unless data[:bestMatches]

    data[:bestMatches].map do |match|
      Stock.new(
        ticker: match[:'1. symbol'],
        name: match[:'2. name']
      )
    end
  rescue StandardError => e
    Rails.logger.error "Stock search API error: #{e.message}"
    []
  end
end
