class StocksController < ApplicationController
  protect_from_forgery except: :search
  def search
    query = params[:query].to_s.strip

    @results = fetch_local_stocks(query)

    if @results.empty? && query.length > 2
      @results = SearchStockService.fetch_stock_search(query) || []
    end

    @results.uniq! { |s| s[:ticker] }

    respond_to do |format|
      format.turbo_stream
      format.html { render :new }
    end
  end

  def ipo
    @ipo_list = Rails.cache.fetch("#{Date.today}-#{params[:year]}", expires_in: 1.weeks) { fetch_recent_ipo }

    if params[:issue_type].present?
      @ipo_list.select! { |ipo| ipo["Issue Type"] == params[:issue_type] }
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

    def fetch_recent_ipo
      listing=[]
      params_year = params[:year] || 2025

      case params_year
      when "2022-25"
        prev_year = 4
      when "2023-25"
        prev_year = 3
      when "2024-25"
        prev_year = 2
      end

      if prev_year
        prev_year.times do |i|
          response = HTTParty.get("https://webnodejs.chittorgarh.com/cloud/report/data-read/125/1/7/#{2025-i}/2025-26/0/all/0?search=&v=15-33") # 29/7
          response.code
          listing += response.parsed_response["reportTableData"]
        end
      else
        puts "\n\n\n#{params_year}\n\n\n"
        response = HTTParty.get("https://webnodejs.chittorgarh.com/cloud/report/data-read/125/1/7/#{params_year}/2025-26/0/all/0?search=&v=15-33") # 29/7
        response.code
        listing = response.parsed_response["reportTableData"]
      end

      listing.map do |l|
        company = l["Company"]
        l["Company"] = company.split("<")&.first
        cmp = l["Market Price (Rs.)"].split(" ").first&.gsub(",", "").to_f
        lp = l["Close Price on Listing (Rs.)"].split(" ").first&.gsub(",", "").to_f
        change = (cmp - lp)/lp * 100
        l["Market Price (Rs.)"]= "#{cmp} (#{change.round(2)}%)"

        l
      end
    end
end
