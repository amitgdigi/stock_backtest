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
    prices = @stock.stock_prices
                   .where(date: @strategy.start_date..@strategy.end_date)
                   .order(:date)
                   .pluck(:date, :close_price)

    return cleanup_and_fail("No price data available, Please try later") if prices.empty?

    @last_traded_price = prices.first[1]
    open_ladder(@last_traded_price, prices.first[0]) # Initial buy

    prices.drop(1).each do |date, current_price|
      handle_stock_split if @last_traded_price > current_price * 1.9

      # Sell
      @active_ladders.dup.each do |ladder|
        if price_up_from?(ladder[:price], current_price, @sell_profit_percentage)
          sell_ladder(ladder, date, current_price)
        end
      end

      # Buy
      @last_traded_price = [ @last_traded_price, current_price ].max
      if price_down_from?(@last_traded_price, current_price, @buy_dip_percentage)
        open_ladder(current_price, date)
      end
    end

    @strategy.update(status: "completed")

    @transactions.pluck(:id).each_cons(2) do |first_id, second_id|
      if first_id > second_id
        @strategy.destroy
        raise StandardError, "Something went wrong, please try again"
      end
    end
    { active_ladders: @active_ladders }
  rescue StandardError => e
    { error: "Backtest failed: #{e.message}" }
  end

  private

  def cleanup_and_fail(msg)
    @strategy.destroy
    @transactions.each(&:destroy)
    { error: msg }
  end

  def open_ladder(price, date)
    quantity = quantity_on_amount(price)
    transaction = build_transaction("buy", date, price, quantity)

    if transaction.save
      @transactions << transaction
      @active_ladders << { id: transaction.id, price: price, quantity: quantity }
    end
  end

  def sell_ladder(ladder, date, price)
    transaction = build_transaction("sell", date, price, ladder[:quantity])

    if transaction.save
      @transactions << transaction
      close_transaction(ladder[:id])
      @active_ladders.delete(ladder)
    end
  end

  def close_transaction(id)
    Transaction.where(id:).update_all(open: false) # Faster than find + update
  end

  def quantity_on_amount(price)
    [ (@investment_amount/price).to_i, 1 ].max
  end

  def handle_stock_split
    @last_traded_price /= 2
    @transactions.each { |t| t.update(price: t.price / 2, quantity: t.quantity * 2) }
  end

  def build_transaction(type, date, price, quantity)
    @last_traded_price = price
    Transaction.new(backtest_id: @strategy.id,
      kind: type,
      date:,
      price:,
      quantity:,
      amount: (quantity * price)
    )
  end

  def price_up_from?(buy_price, current_price, percent)
    ((current_price - buy_price) / buy_price) * 100 >= percent
  end

  def price_down_from?(last_price, current_price, percent)
    ((current_price - last_price) / last_price) * 100 <= -percent
  end
end
