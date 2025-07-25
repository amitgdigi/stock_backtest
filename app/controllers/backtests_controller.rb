class BacktestsController < ApplicationController
  def new
    @stocks = Stock.all
    @backtest = Backtest.new(
      stock_id: @stocks.first&.id,
      start_date: Date.current.beginning_of_year - 1.year,
      end_date: Date.current.end_of_year - 1.year,
      investment_amount: 5000,
      sell_profit_percentage: 3.0,
      buy_dip_percentage: 6.0,
      reinvestment_percentage: 50.0
    )
  end

  def create
    @backtest = Backtest.new(backtest_params)

    @backtest.end_date ||= @backtest.start_date + 30
    # Fetch prices
    result = AlphaVantageService.fetch_daily_prices(
      params[:backtest][:ticker],
      @backtest.start_date,
      @backtest.end_date
    )
    if result[:error]
      flash[:alert] = result[:error]
      render :new, status: :unprocessable_entity
      return
    end

    @backtest.stock = result[:stock]
    if @backtest.save
      @result = BacktestService.new(@backtest, max_buy_amount).run
      if @result[:error]
        flash[:alert] = @result[:error]
        render :new, status: :unprocessable_entity
      else
        redirect_to backtest_path(@backtest)
      end
    else
      flash.now[:alert] = @backtest.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @backtest = Backtest.find(params[:id])
    last_price = @backtest.stock.stock_prices.find_by(date: params[:end_date])&.close_price || @backtest.stock.stock_prices.first.close_price

    portfolio = (@backtest.transactions.sum { |t| t.transaction_type == "buy" ? t.quantity : -t.quantity }) * last_price
    profit_loss = @backtest.transactions.sold.present? ? ((@backtest.transactions - @backtest.transactions.unsold_stocks).sum { |t| t.transaction_type == "sell" ? t.amount : -t.amount }) : 0
    final_shares = @backtest.transactions.sum { |t| t.transaction_type == "buy" ? t.quantity : -t.quantity }
    invested_amount = @backtest.transactions.unsold_stocks.sum(&:amount)
    charges = (@backtest.transactions.sum(&:amount) * 0.0023) + @backtest.transactions.sold.count * 16

    @result = {
      portfolio:,
      profit_loss:,
      transactions: @backtest.transactions,
      final_shares:,
      invested_amount:,
      charges:
    }
  end

  def update
    @backtest = Backtest.new(backtest_params)

    @backtest.end_date ||= @backtest.start_date + 30
    # Fetch prices
    result = AlphaVantageService.fetch_daily_prices(
      params[:backtest][:ticker],
      @backtest.start_date,
      @backtest.end_date
    )

    if result[:error]
      flash[:alert] = result[:error]
      render :new, status: :unprocessable_entity
      return
    end

    @backtest.stock = result[:stock]
    if @backtest.save

      @result = BacktestService.new(@backtest, max_buy_amount).run
      if @result[:error]
        flash[:alert] = @result[:error]
        render :new, status: :unprocessable_entity
      else

        redirect_to backtest_path(@backtest)
      end
    else
      flash.now[:alert] = @backtest.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  private
    def max_buy_amount
      params[:backtest][:maximum_buy_amount].to_i
    end

    def set_backtest
      @backtest = Backtest.find(params[:id])
    end

    def backtest_params
      params.require(:backtest).permit(
        :start_date, :end_date, :investment_amount,
        :sell_profit_percentage, :buy_dip_percentage, :reinvestment_percentage
      )
    end
end
