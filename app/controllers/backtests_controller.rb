class BacktestsController < ApplicationController
  def new
    @recent_tested_stocks = recent_stocks
    @backtest = Backtest.new(default_backtest_attributes)
  end

  def create
    symbol = params[:ticker] || params.dig(:backtest, :ticker)
    return redirect_to new_backtest_path, alert: "Ticker symbol is missing." if symbol.blank?

    if (available = Backtest.joins(:stock).find_by(custom_params(symbol)))
      return redirect_to backtest_path(available)
    end

    stock = Stock.find_by(ticker: symbol)
    @backtest = build_backtest(stock)
    unless stock&.stock_prices&.present?
      NseHistoricalDataJob.perform_later(symbol)
      return redirect_to new_backtest_path, notice: "Records are being fetched. Please try again after a few moments.\n\nPlease wait at least 2 minutes.\n \nCollecting 5 Year record"
    end

    @backtest.end_date ||= @backtest.start_date + 30

    unless @backtest.save
      flash.now[:alert] = @backtest.errors.full_messages.join(", ")
      return render_new_form
    end

    result = BacktestService.new(@backtest, max_buy_amount).run
    if result[:error]
      flash.now[:alert] = result[:error]
      return render_new_form
    end

    redirect_to backtest_path(@backtest)
  end

  def show
    last_price = backtest.stock.stock_prices.find_by(date: params[:end_date])&.close_price || backtest.stock.stock_prices.last.close_price

    portfolio = (backtest.transactions.sum { |t| t.buy? ? t.quantity : -t.quantity }) * last_price
    profit_loss = backtest.transactions.sold(backtest_id: backtest.id).present? ? ((backtest.transactions - backtest.transactions.unsold_stocks).sum { |t| t.sell? ? t.amount : -t.amount }) : 0
    final_shares = backtest.transactions.sum { |t| t.buy? ? t.quantity : -t.quantity }
    invested_amount = backtest.transactions.unsold_stocks.sum(&:amount)
    sold_count = backtest.transactions.sold(backtest_id: backtest.id).filter { |t| t.quantity > 0 }.count
    charges = (backtest.transactions.sum(:amount) * 0.003321) + (sold_count * 16)

    @backtest=backtest
    @result = {
      portfolio:,
      profit_loss:,
      transactions: backtest.transactions.order(:date),
      final_shares:,
      invested_amount:,
      charges:
    }
  end

  def update
    backtest.end_date ||= backtest.start_date + 30
    if backtest.update!(backtest_params)

      @result = BacktestService.new(backtest, max_buy_amount).run
      if @result[:error]
        flash[:alert] = @result[:error]
        render :new, status: :unprocessable_content
      else

        redirect_to backtest_path(backtest)
      end
    else
      flash.now[:alert] = backtest.errors.full_messages.join(", ")
      render :new, status: :unprocessable_content
    end
  end

  private
    def render_new_form
      @recent_tested_stocks = recent_stocks
      render :new, status: :unprocessable_content
    end

    def custom_params(symbol)
      backtest_params.merge(stocks: { ticker: symbol }).merge(status: :completed)
    end

    def backtest
      @_backtest ||= Backtest.find(params[:id])
    end

    def backtest_params
      params.require(:backtest).permit(
        :start_date, :end_date, :investment_amount, :maximum_buy_amount,
        :sell_profit_percentage, :buy_dip_percentage, :reinvestment_percentage
      )
    end

    def recent_stocks
      Backtest.order(id: :desc)
              .limit(30)
              .includes(:stock)
              .map(&:stock)
              .uniq
              .first(10)
    end

    def default_backtest_attributes
      last = Backtest.last
      {
        stock_id: recent_stocks.first&.id,
        start_date: last&.start_date || Date.current.beginning_of_year - 1.year,
        end_date: last&.end_date || Date.today,
        investment_amount: last&.investment_amount&.to_i || 5000,
        maximum_buy_amount: last&.maximum_buy_amount&.to_i || 5000,
        sell_profit_percentage: last&.sell_profit_percentage&.to_i || 10,
        buy_dip_percentage: last&.buy_dip_percentage&.to_i || 10,
        reinvestment_percentage: last&.reinvestment_percentage&.to_i || 50
      }
    end

    def build_backtest(stock)
      Backtest.new(backtest_params).tap do |bt|
        bt.stock = stock
      end
    end

    def max_buy_amount
      params.dig(:backtest, :maximum_buy_amount).to_i
    end
end
