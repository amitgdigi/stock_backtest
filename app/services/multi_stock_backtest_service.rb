class MultiStockBacktestService
  def initialize(stock, multi_stock)
    @stock = stock
    @multi_stock = multi_stock
    @transactions = []
    @last_traded_price = nil
    @reinvestment = @multi_stock.reinvestment_percentage
  end

  def run
    prices = @stock.stock_prices
      .where(date: @multi_stock.start_date..@multi_stock.end_date)
      .order(:date)
      .pluck(:date, :close_price, :open_price)

    return { error: "No price data available, Please try later" } if prices.empty?

    # Initial buy
    @last_traded_price = prices.first[1]
    buy_first = false
    @transactions << save_transaction("buy", @multi_stock.start_date, @last_traded_price)

    # Iterate through each day (skip first day)
    prices.drop(1).each do |current_date, current_price, open_price|
      # Assuming if stocks split happens, previous price would definitely be twice of the next day price
      handle_stock_split(open_price) if @last_traded_price > (current_price*1.9)
      price_change_percent = ((current_price - @last_traded_price) / @last_traded_price) * 100

      # Sell
      if !buy_first && price_change_percent >= @multi_stock.sell_profit_percentage
        @transactions << save_transaction("sell", current_date, current_price)
        @last_traded_price = current_price
        buy_first = true

      # Buy
      elsif price_change_percent <= -@multi_stock.buy_dip_percentage
        buy_first = false
        @transactions << save_transaction("buy", current_date, current_price)
        # unsold = @multi_stock.transactions.unsold_stocks
        @last_traded_price = buy_first ? current_price : (@last_traded_price + current_price)*@reinvestment/100
        # @last_traded_price = unsold.size > 0 ? unsold.sum(&:price)/unsold.size : current_price
      end
      @last_traded_price = [ @last_traded_price, current_price ].max if buy_first
    end

    # Update multi_stock status
    @multi_stock.stocks << @stock
    @multi_stock.update(status: "completed")
    @transactions.flatten
  rescue StandardError => e
    { error: "Multi Stock Backtest failed: #{e.message}" }
  end

  private

  def handle_stock_split(open_price)
    split_ratio = (@last_traded_price/open_price).round
    @last_traded_price /=split_ratio
    @transactions.each do |t|
      t.update(price: t.price/split_ratio)
    end
  end

  def save_transaction(type, date, price)
     Transaction.create!(
      multi_stock_id: @multi_stock.id,
      kind: type,
      date:,
      price:,
      quantity: 0,
      amount: 0,
      stock_id: @stock.id
    )
  end
end
