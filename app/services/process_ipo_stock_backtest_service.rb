class ProcessIpoStockBacktestService
  T_CHARGE = ENV.fetch("TRANSACTION_CHARGES_PERCENTAGE", 0.00223).to_f
  CHARGE = ENV.fetch("SELLING_CHARGES_RUPEES", 16).to_f

  def initialize(params)
    @params = params.to_h.symbolize_keys
    @total_amount = 0.0
  end

  # returns IpoStock or { wait: true, missing: [...] }
  def run
    fetch_stock_symbols
    if @missing_symbols.present?
      return { wait: true, notice: "We are fetching records, Please try again", missing: @missing_symbols }
    end

    return { wait: true, notice: "Something wrong at records fetching, Please Check", missing: @missing_symbols } unless confirmed_stock_prices?

    perform_backtest_and_persist
  end

  private

  def fetch_stock_symbols
    @symbols = Array(@params[:stock_symbols]).map(&:upcase)
    stocks = Stock.where(ticker: @symbols)
    # trigger background fetch for missing or empty price data
    @missing_symbols = []
    @symbols.each do |symbol|
      s = stocks.detect { |st| st.ticker == symbol }
      if s.nil?
        fetch_stock_prices(symbol)
        @missing_symbols << symbol
      elsif s.stock_prices.empty?
        fetch_stock_prices(symbol)
        @missing_symbols << symbol
      end
    end
  end

  def fetch_stock_prices(symbol)
    # enqueue job that will populate Stock and StockPrice data
    NseHistoricalDataJob.perform_later(symbol)
  end

  def confirmed_stock_prices?
    @symbols.all? { |symbol| Stock.find_by(ticker: symbol)&.stock_prices&.exists? }
  end

  # Run backtests (pure simulation), persist the IpoStock and transactions at the end
  def perform_backtest_and_persist
    @ipo_stock = IpoStock.create!(@params.except(:symbols, :stock_symbols))
    @total_amount = @ipo_stock.total_amount || 0.0

    Stock.where(ticker: @symbols).find_each do |stock|
      service = IpoStockBacktestService.new(stock, @ipo_stock)
      txn_hashes = service.run # array of txn hashes (pure data)
      next if txn_hashes.blank?

      # persist transactions for this stock in order
      txn_hashes.each do |h|
        @ipo_stock.transactions.create!(
          kind: h[:kind],
          date: h[:date],
          price: h[:price],
          quantity: h[:quantity],
          amount: h[:amount],
          stock: stock
        )
      end

      # attach stock
      @ipo_stock.stocks << stock unless @ipo_stock.stocks.exists?(stock.id)
    end

    # after persisting all transactions, apply sequential cash accounting
    apply_transaction_logic

    @ipo_stock.update(total_amount: @total_amount)
    @ipo_stock
  end

  def apply_transaction_logic
    @max_buy_amount = @ipo_stock.maximum_buy_amount
    @initial_buy_amount = @ipo_stock.investment_amount
    @total_amount = 0.0

    @ipo_stock.transactions.order(:date)#Calculate total bought amount for all stock
    .group_by(&:date).each do |date, daily_transactions|
      daily_transactions.sort_by(&:stock_id).each do |t|
        if t.buy?
          handle_buy(t)
        else
          handle_sell(t)
        end
      end
    end
# ========================Begin=========================
    @ipo_stock.transactions.order(:date)#Calculate total bought amount for each stock respectively
    .group_by(&:stock).each do |date, daily_transactions|
     @stock_amount = 0.00
      daily_transactions.sort_by(&:date).each do |t|
        if t.buy?
          handle_buy_stock(t)
        else
          handle_sell_stock(t)
        end
      end
    end
  end

  def handle_buy_stock(t)
    # if related unsold previous buys exist -> treat as reinvest
    unsold = t.collect_unsold_between(include_self: false)
    if unsold.present?
      re_buy_value = unsold.sum(&:amount) * (@ipo_stock.reinvestment_percentage.to_f / 100.0)
      re_buy_value = [re_buy_value, @max_buy_amount].min if @max_buy_amount.to_f > 0.0
      quantity = [1, (re_buy_value / t.price).to_i].max
      amount = quantity * t.price
      if quantity > 0
        charges = (amount * T_CHARGE)
        @stock_amount -= (amount + charges)
        t.update(stock_amount: @stock_amount)
      else
        puts "\n\n#{t.inspect}\n\n"
        t.destroy
      end
    else
      buy_value = @initial_buy_amount.to_f
      quantity = [0, (buy_value / t.price).to_i].max
      amount = quantity * t.price
      if quantity > 0
        charges = (amount * T_CHARGE)
        @stock_amount -= (amount + charges)
        t.update(stock_amount: @stock_amount)
      else
        puts "\n\n#{t.inspect}\n\n"
        t.destroy
      end
    end
  end

  def handle_sell_stock(t)
    unsolds = t.collect_unsold_between
    quantity = unsolds.sum(&:quantity)

    amount = quantity * t.price
    if unsolds.present? && quantity > 0
      charges = (amount * T_CHARGE) + CHARGE
      @stock_amount += (amount - charges)
      t.update(stock_amount: @stock_amount)
    else
      t.destroy
    end
  end
# ====================+====END=========================

  def handle_buy(t)
    # if related unsold previous buys exist -> treat as reinvest
    unsold = t.collect_unsold_between(include_self: false)
    if unsold.present?
      re_buy_value = unsold.sum(&:amount) * (@ipo_stock.reinvestment_percentage.to_f / 100.0)
      re_buy_value = [re_buy_value, @max_buy_amount].min if @max_buy_amount.to_f > 0.0
      quantity = [1, (re_buy_value / t.price).to_i].max
      amount = quantity * t.price
      if quantity > 0
        charges = (amount * T_CHARGE)
        @total_amount -= (amount + charges)
        t.update(quantity: quantity, amount: amount, total_amount: @total_amount)
      else
        puts "\n\n#{t.inspect}\n\n"
        t.destroy
      end
    else
      buy_value = @initial_buy_amount.to_f
      quantity = [0, (buy_value / t.price).to_i].max
      amount = quantity * t.price
      if quantity > 0
        charges = (amount * T_CHARGE)
        @total_amount -= (amount + charges)
        t.update(quantity: quantity, amount: amount, total_amount: @total_amount)
      else
        puts "\n\n#{t.inspect}\n\n"
        t.destroy
      end
    end
  end

  def handle_sell(t)
    unsolds = t.collect_unsold_between
    quantity = unsolds.sum(&:quantity)

    amount = quantity * t.price
    if unsolds.present? && quantity > 0
      charges = (amount * T_CHARGE) + CHARGE
      @total_amount += (amount - charges)
      t.update(quantity: quantity, amount: amount, total_amount: @total_amount)
    else
      t.destroy
    end
  end
end
