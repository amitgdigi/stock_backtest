class StocksController < ApplicationController
  def search
    query = params[:query]
    local_stocks = Stock.where("ticker ILIKE ? OR name ILIKE ?", "%#{query}%", "%#{query}%").limit(10)
    api_stocks = (local_stocks.empty? && query.length >= 3) ? SearchStockService.fetch_stock_search(query) : []

    results = (local_stocks + api_stocks).uniq { |s| s[:ticker] }.map do |stock|
      { ticker: stock.ticker, name: stock.name }
    end

    render json: results
  end
end
