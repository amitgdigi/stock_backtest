class ProcessMultiStockBacktestService
  def initialize(params)
    @params = params.to_h.symbolize_keys
    @total_amount = 200000.0
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
    @multi_stock.transactions.order(:date)
    .group_by(&:date).each do |date, daily_transactions|
      daily_transactions.each do |t|
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
      quantity = (re_buy_value / t.price).to_i
      amount = quantity * t.price
      @total_amount -= amount
      t.update(quantity:, amount:)
    else
      buy_value = @total_amount/0.3e2
      quantity = (buy_value / t.price).to_i
      amount = quantity * t.price
      return if @total_amount < amount

      @total_amount -= amount
      t.update(quantity:, amount:)
    end
  end

  def handle_sell(t)
    quantity = t.collect_unsold_between.sum(&:quantity)
    amount = quantity * t.price
    @total_amount += amount
    t.update(quantity:, amount:)
  end
end
