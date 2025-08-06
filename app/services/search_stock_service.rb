require "httparty"
require "json"

class SearchStockService
  BASE_URL = "https://www.nseindia.com/api/search/autocomplete"
  HEADERS = {
    "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/122.0.0.0 Safari/537.36",
    "Accept" => "*/*",
    "Accept-Language" => "en-US,en;q=0.9"
  }


  def self.fetch_stock_search(query)
    response = HTTParty.get(BASE_URL, query: { q: query }, headers: HEADERS)

    data = JSON.parse(response.body, symbolize_names: true)
    return [] unless data[:symbols]

    data[:symbols].map do |match|
      Stock.new(
        ticker: match[:'symbol'],
        name: match[:'symbol_info'],
        listing_date: match[:'listing_date']
      )
    end
  rescue StandardError => e
    Rails.logger.error "Stock search API error: #{e.message}"
    []
  end
end
