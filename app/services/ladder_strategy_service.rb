class LadderStrategyService
  def initialize(strategy)
    @strategy = strategy
    @stock = strategy.stock
    @investment_amount = strategy.investment_amount
    @buy_dip_percentage = strategy.buy_dip_percentage
    @sell_profit_percentage = strategy.sell_profit_percentage

    @active_ladders = [] # [{price: 100, quantity: 10}]
    @transactions = []
  end

  def run
    prices = @stock.stock_prices.where(date: @strategy.start_date..@strategy.end_date)
                     .order(:date)
                     .map { |p| { date: p.date, close_price: p.close_price } }

    [ @strategy.destroy, @transactions.destroy ] if prices.empty?
    return { error: "No price data available, Please try later" } if prices.empty?

    @last_traded_price = prices.first[:close_price]
    open_ladder(@last_traded_price, prices.first[:date]) # Initial buy


    prices[1..-1].each do |price_data|
      current_price = price_data[:close_price]
      date = price_data[:date]

      handle_stock_split if @last_traded_price > (current_price*1.9)

      # Sell
      @active_ladders.dup.each do |ladder|
        if price_up_from?(ladder[:price], current_price, @sell_profit_percentage)
          sell_ladder(ladder, date, current_price)
        end
      end

      # Buy
      @last_traded_price = [ @last_traded_price, current_price ].max
      if @last_traded_price
        if price_down_from?(@last_traded_price, current_price, @buy_dip_percentage)
          open_ladder(current_price, date)
        end
      end
    end

    @strategy.update(status: "completed")

    { active_ladders: @active_ladders }
  rescue StandardError => e
    { error: "Backtest failed: #{e.message}" }
  end

  private

  def open_ladder(price, date)
    quantity = quantity_on_amount(price)

    save_transaction("buy", date, price, quantity)
    @active_ladders << { id: @transactions.last.id, price:, quantity: }
  end

  def sell_ladder(ladder, date, price)
    save_transaction("sell", date, price, ladder[:quantity])
    close_transaction(ladder[:id])
    @active_ladders.delete(ladder)
  end

  def close_transaction(id)
    Transaction.find_by(id:).update(open: false)
  end

  def quantity_on_amount(price)
    (@investment_amount/price).to_i
  end

  def handle_stock_split
    @last_traded_price = @last_traded_price / 2
    @transactions.each do |t|
      t.update(price: t.price/2, quantity: t.quantity*2)
    end
  end

  def save_transaction(type, date, price, quantity)
    amount = (quantity * price).round(2)
    @last_traded_price = price

    @transactions << Transaction.create!(
      backtest_id: @strategy.id,
      transaction_type: type,
      date: date,
      price: price,
      quantity: quantity,
      amount: amount
    )
  end

  def price_up_from?(buy_price, current_price, percent)
    ((current_price - buy_price) / buy_price) * 100 >= percent
  end

  def price_down_from?(last_price, current_price, percent)
    ((current_price - last_price) / last_price) * 100 <= -percent
  end
end
