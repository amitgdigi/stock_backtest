class StocksController < ApplicationController
  protect_from_forgery except: :search
  def search
    query = params[:query].to_s.strip

    @results = fetch_local_stocks(query)

    if @results.empty? && query.length >= 3
      @results = SearchStockService.fetch_stock_search(query) || []
    end

    @results.uniq! { |s| s[:ticker] }

    respond_to do |format|
      format.turbo_stream
      format.html { render :new }
    end
  end

  private
    def fetch_local_stocks(query)
      return [] if query.blank?

      Stock
        .where("ticker ILIKE :q OR name ILIKE :q", q: "%#{query}%")
        .limit(10)
        .map do |s|
          {
            ticker: s.ticker,
            name: s.name.present? ? "#{s.ticker} - #{s.name}" : s.ticker
          }
        end
    end
end
