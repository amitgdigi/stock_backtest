class ProcessMultiStockBacktestService
  T_CHARGE = ENV.fetch("TRANSACTION_CHARGES_PERCENTAGE", 0.00223)
  CHARGE = ENV.fetch("SELLING_CHARGES_RUPEES", 16)
  SPLIT_TRADE_DAY = ENV.fetch("SPLIT_TRADE_DAY", 30)

  def initialize(params)
    @params = params.to_h.symbolize_keys
    @total_amount = 0.0
  end

  def run
    fetch_stock_symbols
    return { wait: true, notice: "We are fetching records, Please try again", missing: @missing_symbols } if @missing_symbols.present?

    return { wait: true, notice: "Something wrong at records fetching, Please Check", missing: @missing_symbols } unless confirmed_stock_prices?

    perform_backtest
    apply_transaction_logic

    @multi_stock.update(total_amount: @total_amount)
    @multi_stock
  end

  private

  def fetch_stock_symbols
    @symbols = @params[:stock_symbols]&.map(&:upcase)
    stocks = Stock.where(ticker: @symbols)
    stocks.each do |stock|
      fetch_stock_prices(stock.ticker) if stock.stock_prices.empty?
    end
    @missing_symbols = (@symbols - stocks.pluck(:ticker))
    @missing_symbols.each do |symbol|
      fetch_stock_prices(symbol)
    end
  end

  def fetch_stock_prices(symbol)
    NseHistoricalDataJob.perform_later(symbol)
  end

  def confirmed_stock_prices?
    @symbols.none? { |symbol| stock_prices_pending?(symbol) }
  end

  def stock_prices_pending?(symbol)
    !(Stock.find_by(ticker: symbol)&.stock_prices&.exists?)
  end

  def perform_backtest
    @multi_stock = MultiStock.create(@params.except(:symbols, :stock_symbols))
    # @multi_stock = MultiStock.find_or_create_by(@params.except(:symbols, :stock_symbols))
    @total_amount = @multi_stock.total_amount

    Stock.where(ticker: @symbols).map do |stock|
      MultiStockBacktestService.new(stock, @multi_stock).run
    end
  end

  def apply_transaction_logic
    @max_buy_amount = @multi_stock.maximum_buy_amount
    @initial_buy_amount = @multi_stock.investment_amount
    @multi_stock.transactions.order(:date)
    .group_by(&:date).each do |date, daily_transactions|
      daily_transactions.sort_by(&:stock_id).each do |t|
        if t.buy?
          handle_buy(t)
        else
          handle_sell(t)
        end
      end
    end
  end

  def handle_buy(t)
    if t.collect_unsold_between.present?
      re_buy_value = t.collect_unsold_between.sum(&:amount) * @params[:reinvestment_percentage].to_f / 100
      re_buy_value = [ re_buy_value, @max_buy_amount ].min if @max_buy_amount > 0
      quantity = (re_buy_value / t.price).to_i
      amount = quantity * t.price
      if @total_amount >= amount && quantity > 0
        charges = (amount * T_CHARGE.to_f)
        @total_amount -= (amount + charges)
        t.update(quantity:, amount:, total_amount: @total_amount)
      else
        t.destroy
      end
    else
      buy_value = @total_amount/SPLIT_TRADE_DAY.to_f
      buy_value = [ buy_value, @initial_buy_amount ].max if @initial_buy_amount > 0
      quantity = (buy_value / t.price).to_i
      amount = quantity * t.price
      if @total_amount >= amount && quantity > 0
        charges = (amount * T_CHARGE.to_f)
        @total_amount -= (amount + charges)
        t.update(quantity:, amount:, total_amount: @total_amount)
      else
        t.destroy
      end
    end
  end

  def handle_sell(t)
    unsolds = t.collect_unsold_between
    quantity = unsolds.sum(&:quantity)

    amount = quantity * t.price
    if unsolds.present? && quantity > 0
      charges = (amount * T_CHARGE.to_f) + CHARGE.to_f
      @total_amount += (amount - charges)
      t.update(quantity:, amount:, total_amount: @total_amount)
    else
      t.destroy
    end
  end
end
