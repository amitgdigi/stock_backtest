class IpoStockBacktestService
  def initialize(stock, ipo_stock)
    @stock = stock
    @ipo_stock = ipo_stock
    @transactions = []
    @investment_amount = @ipo_stock.investment_amount.to_f
    @max_buy_amount = @ipo_stock.maximum_buy_amount.to_f
    @reinvestment_pct = @ipo_stock.reinvestment_percentage.to_f
    @buy_dip = @ipo_stock.buy_dip_percentage.to_f
    @first_buy_pct = @ipo_stock.first_buy_percentage.to_f
    @sell_profit_pct = @ipo_stock.sell_profit_percentage.to_f
    @portfolio = { shares: 0, cash: 0.0, avg_price: nil }
    @last_anchor_price = nil
    @total_bought_amount_for_stock = @ipo_stock.total_bought_amount_for_stock.to_f
    @total_bought_amount = 0.0
  end

  # returns array of txn hashes
  def run
    prices = @stock.stock_prices
      .where(date: @ipo_stock.start_date..@ipo_stock.end_date)
      .order(:date)
      .pluck(:date, :open_price, :high_price, :low_price, :close_price)

    return [] if prices.empty?

    # Phase 1: find initial buy based on highest-seen -> drop by first_buy_percentage
    max_seen = prices.first[2] # high_price
    initial_buy_idx = nil
    prices.each_with_index do |(date, _open, high, low, close), idx|
      max_seen = [max_seen, high].compact.max
      target = max_seen * (1 - @first_buy_pct / 100.0)
      if low && low <= target
        initial_buy_idx = idx
        @last_anchor_price = close || high || low
        break
      end
    end

    return [] unless initial_buy_idx

    # Perform initial buy
    date, _o, _h, _l, close_price = prices[initial_buy_idx]
    price = (@last_anchor_price || close_price).to_f
    initial_qty = [(@investment_amount / price).to_i, 1].max
    add_txn(:buy, date, price, initial_qty)
    update_portfolio_buy(price, initial_qty)

    state = :holding   # because we already did initial buy
    @cycle_high = @last_anchor_price  # initial cycle high = initial anchor
    
    prices[(initial_buy_idx + 1)..-1].each do |date, open_p, high_p, low_p, close_p|
      close = close_p.to_f
      high  = high_p.to_f
      low   = low_p.to_f

    # ======== STOCK SPLIT CHECK ========
    if @last_anchor_price && open_p && @last_anchor_price > (open_p.to_f * 1.9)
      handle_stock_split(open_p.to_f)
    end

    # STATE MACHINE ===========================================================
    case state
    # ------------------------------------------------------------------------
    when :holding
      # Track new highs during holding stage
      @cycle_high = [@cycle_high, high].max

      # Check for sell
      change_pct = ((close - @last_anchor_price) / @last_anchor_price) * 100.0

      if change_pct >= @sell_profit_pct && @portfolio[:shares] > 0
        qty = @portfolio[:shares]

        add_txn(:sell, date, close, qty)
        update_portfolio_sell(close)

        # After sell → enter waiting state
        state = :waiting_for_drop
        @cycle_high = nil        # reset cycle high
        @last_anchor_price = nil # anchor only applies during holding

        next
      end

      # Check for averaging down (buy dip)
      dip_pct = ((close - @last_anchor_price) / @last_anchor_price) * 100.0
      if dip_pct <= -@buy_dip

        # BUY STOP CONDITION
        if @total_bought_amount >= @total_bought_amount_for_stock
          next
        end

        reinvest_amount =
          if @portfolio[:shares] > 0
            (@portfolio[:cash].abs * (@reinvestment_pct / 100.0)).abs
          else
            @investment_amount
          end
        reinvest_amount = [reinvest_amount, @max_buy_amount].min if @max_buy_amount > 0

        qty = [(reinvest_amount / close).to_i, 1].max

        add_txn(:buy, date, close, qty)
        update_portfolio_buy(close, qty)

        @last_anchor_price = @portfolio[:avg_price]
        next
      end
      # ------------------------------------------------------------------------
      when :waiting_for_drop
        # Build cycle-high AFTER sell
        @cycle_high = @cycle_high.nil? ? high : [@cycle_high, high].max

        next if @cycle_high.nil? || @cycle_high.zero?

        # Calculate drop from new cycle-high
        drop_pct = ((close - @cycle_high) / @cycle_high) * 100.0

        if drop_pct <= -@first_buy_pct
          # BUY STOP CONDITION
          if @total_bought_amount >= @total_bought_amount_for_stock
            next
          end

          qty = [( @investment_amount / close ).to_i, 1].max

          add_txn(:buy, date, close, qty)
          update_portfolio_buy(close, qty)

          state = :holding
          @last_anchor_price = close
          @cycle_high = close
          next
        end
      end
    end

    @transactions
  rescue StandardError => e
    Rails.logger.error("IpoStockBacktestService failed for #{@stock.ticker}: #{e.message}")
    []
  end

  private
    def add_txn(kind, date, price, quantity)
      amount = (quantity * price).round(2)

      # track cumulative buy amount
      @total_bought_amount += amount if kind.to_s == "buy"
      @total_bought_amount = 0.0 if kind.to_s == "sell"

      @transactions << { kind: kind.to_s, date: date, price: price.to_f, quantity: quantity.to_i, amount: amount }
    end

    def update_portfolio_buy(price, quantity)
      qty = quantity.to_i
      cost = qty * price.to_f
      if @portfolio[:shares] <= 0
        @portfolio[:avg_price] = price.to_f
      else
        total_cost = @portfolio[:avg_price].to_f * @portfolio[:shares] + cost
        @portfolio[:avg_price] = total_cost / (@portfolio[:shares] + qty)
      end
      @portfolio[:shares] += qty
      @portfolio[:cash] -= cost
    end

    def update_portfolio_sell(price)
      proceeds = @portfolio[:shares] * price.to_f
      @portfolio[:cash] = 0
      @portfolio[:shares] = 0
      @portfolio[:avg_price] = nil
    end

    def handle_stock_split(open_price)
      ratio = (@last_anchor_price / open_price).round
      return if ratio <= 1
      @last_anchor_price /= ratio
      @portfolio[:shares] *= ratio
      @portfolio[:avg_price] = @portfolio[:avg_price].to_f / ratio if @portfolio[:avg_price]
      @transactions.each do |t|
        t[:price] = (t[:price] / ratio).round(4)
        t[:quantity] = t[:quantity] * ratio
      end
    end
end
