class StocksController < ApplicationController
  protect_from_forgery except: :search
  def search
    query = params[:query]
    local_stocks = Stock.where("ticker ILIKE ? OR name ILIKE ?", "%#{query}%", "%#{query}%").limit(10)

    api_stocks = (local_stocks.empty? && query.length >= 3) ? SearchStockService.fetch_stock_search(query) : []

    @results = (local_stocks + api_stocks).uniq

    respond_to do |format|
      format.turbo_stream
      format.html { render :new }
    end
  end
end
