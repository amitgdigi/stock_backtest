class Backtests::LadderController < ApplicationController
  def new
    @recent_tested_stocks = Backtest.order(id: :desc).limit(30).includes(:stock).map(&:stock).uniq.first(10)
    backtest = Backtest.last
    @backtest = Backtest.new(
      stock_id: @recent_tested_stocks.first&.id,
      start_date: backtest&.start_date || Date.current.beginning_of_year - 1.year,
      end_date: backtest&.end_date || Date.today || Date.current.end_of_year - 1.year,
      investment_amount: backtest&.investment_amount.to_i || 5000,
      sell_profit_percentage: backtest&.sell_profit_percentage.to_i || 10,
      buy_dip_percentage: backtest&.buy_dip_percentage.to_i || 10,
    )
  end

  def create
    if available_backtest = Backtest.find_by(backtest_params.merge(status: :completed))
      return redirect_to backtests_ladder_path(available_backtest)
    end

    backtest = Backtest.new(backtest_params)
    backtest.end_date ||= backtest.start_date + 30
    # Fetch prices
    result = AlphaVantageService.fetch_daily_prices(
      params[:ticker] || params[:backtest][:ticker],
      backtest.start_date,
      backtest.end_date
    )
    if result[:error]
      flash[:alert] = result[:error]
      render :new, status: :unprocessable_entity
      return
    end

    backtest.stock = result[:stock]

    if backtest.save
      result = LadderStrategyService.new(backtest).run
      if result[:error]
        flash[:alert] = result[:error]
        render :new, status: :unprocessable_entity
      else
        redirect_to backtests_ladder_path(backtest)
      end
    else
      flash.now[:alert] = backtest.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def show
    stock_prices = backtest.stock.stock_prices
    transactions = backtest.transactions
    last_price = transactions.last&.[](:price) || stock_prices.first.close_price

    active_buys = transactions.where(transaction_type: :buy, open: true)


    portfolio = active_buys.sum(:quantity) * last_price

    profit_loss = transactions.sold.present? ? ((transactions - active_buys).sum { |t| t.transaction_type == "sell" ? t.amount : -t.amount }) : 0
    final_shares = active_buys.sum(&:quantity)
    invested_amount = active_buys.sum(:amount)
    charges = (transactions.sum(:amount) * 0.0023) + transactions.sold.size * 16

    @backtest = backtest
    @result = {
      portfolio:,
      profit_loss:,
      transactions:,
      final_shares:,
      invested_amount:,
      charges:,
      unrealized_pl: portfolio - invested_amount,
      active_buys:
    }
  end

  def update
    backtest.end_date ||= backtest.start_date + 30
    if backtest.update!(backtest_params)

      @result = BacktestService.new(backtest).run
      if @result[:error]
        flash[:alert] = @result[:error]
        render :new, status: :unprocessable_entity
      else

        redirect_to backtests_ladder_path(backtest)
      end
    else
      flash.now[:alert] = backtest.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  private
    def backtest
      @_backtest ||= Backtest.find(params[:id])
    end

    def backtest_params
      params.require(:backtest).permit(
        :start_date, :end_date, :investment_amount,
        :sell_profit_percentage, :buy_dip_percentage
      )
    end
end
