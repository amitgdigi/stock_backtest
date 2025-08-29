class BacktestService
  def initialize(backtest, max_buy_amount)
    @backtest = backtest
    @stock = backtest.stock
    @max_buy_amount = max_buy_amount
    @investment_amount = backtest.investment_amount
    @portfolio = { shares: 0, cash: 0.0 }
    @transactions = []
    @last_purchase_price = nil
  end

  def run
    # Fetch or use cached prices
    prices = @stock.stock_prices.where(date: @backtest.start_date..@backtest.end_date)
                      .order(:date)
                      .map { |p| { date: p.date, close_price: p.close_price, open_price: p.open_price } }

    [ @backtest.destroy, @stock.destroy, @transactions.destroy ] if prices.empty?

    return { error: "No price data available, Please try later" } if prices.empty?

    # Initial buy
    first_price = prices.first[:close_price]
    initial_quantity = [ (@investment_amount / first_price).to_i, 1 ].max
    @portfolio[:shares] += initial_quantity
    @portfolio[:cash] -= initial_quantity * first_price
    @last_purchase_price = first_price
    buy_first = false
    save_transaction("buy", prices.first[:date], first_price, initial_quantity)

    # Iterate through each day (skip first day)
    prices[1..-1].each do |price|
      current_price = price[:close_price]
      # Assuming if stocks split happens, previous price would definitely be twice of the next day price
      handle_stock_split(price[:open_price]) if @last_purchase_price > (current_price*1.9)
      price_change_percent = ((current_price - @last_purchase_price) / @last_purchase_price) * 100

      # Sell
      if !buy_first && price_change_percent >= @backtest.sell_profit_percentage
        save_transaction("sell", price[:date], current_price, @portfolio[:shares])
        @portfolio[:shares] = 0
        @portfolio[:cash] = 0
        @last_purchase_price = current_price
        buy_first = true

      # Buy
      elsif price_change_percent <= -@backtest.buy_dip_percentage
        reinvest_amount = @portfolio[:shares] > 0 ? @portfolio[:cash].abs * (@backtest.reinvestment_percentage / 100) : @investment_amount
        reinvest_amount = [ reinvest_amount, @max_buy_amount ].min if @max_buy_amount > 0

        quantity = [ (reinvest_amount / current_price).to_i, 1 ].max
        @portfolio[:shares] += quantity
        @portfolio[:cash] -= quantity * current_price
        buy_first = false
        save_transaction("buy", price[:date], current_price, quantity)
        # Swipe the transactions from the last sell, collect the amount/shares for last purchase price
        @last_purchase_price = (@portfolio[:shares] > 0) ? (@backtest.transactions.unsold_stocks.sum(&:amount) / @portfolio[:shares]) : current_price
      end
      @last_purchase_price = [ @last_purchase_price, current_price ].max if buy_first
    end

    # Update backtest status
    @backtest.update(status: "completed")

    {
      transactions: @transactions,
      final_shares: @portfolio[:shares].round(4),
      final_cash: @portfolio[:cash].round(2)
    }
  rescue StandardError => e
    { error: "Backtest failed: #{e.message}" }
  end

  private

  def handle_stock_split(open_price)
    split_ratio = (@last_purchase_price/open_price).round

    @portfolio[:shares] = @portfolio[:shares] * split_ratio
    @portfolio[:cash] = @portfolio[:cash] / split_ratio
    @last_purchase_price = @last_purchase_price / split_ratio
    @transactions.each do |t|
      t.update(price: t.price/split_ratio, quantity: t.quantity*split_ratio)
    end
  end

  def save_transaction(type, date, price, quantity)
    amount = (quantity * price).round(2)

    @transactions << Transaction.create!(
      backtest_id: @backtest.id,
      kind: type,
      date: date,
      price: price,
      quantity: quantity.round(4),
      amount: amount
    )
  end
end
