class MultiStockController < ApplicationController
  def index
    @stocks = Stock.none
    @multi_stock = MultiStock.new(default_backtest_attributes)
  end

  def search_stock
    query = params[:q].to_s.strip
    stocks = Stock.where("ticker ILIKE ? OR name ILIKE ?", "%#{query}%", "%#{query}%").limit(20)
    if stocks.empty? && query.length > 2
      counter = Stock.last&.id || 0
      collect = SearchStockService.fetch_stock_search(query) || [] #
      stocks = collect.map do |c| counter+=1
        c.id = counter
        c
      end
    end

    render partial: "multi_stock/stock_list", locals: { stocks: stocks }, formats: [ :html ]
  end

  def create
    selected_ids = params[:stock_ids] || []
    session[:selected_stocks] = selected_ids
    redirect_to multi_stock_path(id: "result")
  end

  def show
    portfolio_data = calculate_portfolio

    stock_names = portfolio_data.map { |entry| entry[:stock][:ticker] }.join(",")
    portfolio = portfolio_data.sum { |entry| entry[:portfolio] }
    profit_loss = portfolio_data.sum { |entry| entry[:pnl] }
    final_shares  = portfolio_data.sum { |entry| entry[:final_shares] }
    invested_amount  = portfolio_data.sum { |entry| entry[:invested_amount] }
    charges = portfolio_data.sum { |entry| entry[:charges] }

    @multi_stock = multi_stock

    @result = {
      stock_names:,
      portfolio:,
      profit_loss:,
      transactions: multi_stock.transactions.order(:date, :id).map(&:serialize),
      final_shares:,
      invested_amount:,
      total_amount: multi_stock.total_amount,
      charges:,
      portfolio_data:
    }
  end

  def backtest
    stock_params =stock_symbols_params

    service = ProcessMultiStockBacktestService.new(multi_stock_params.merge(stock_params))

    if result = service.run
      if result.is_a?(Hash) && result[:wait]
        return redirect_to multi_stock_index_path, notice: "We are fetching missing stock data: #{result[:missing].join(', ')}. Please try again in a few minutes."
      end

      redirect_to multi_stock_path(result.id)
    else
      redirect_to multi_stock_index_path, alert: "Could not run backtest. Missing data?\nWe are fetching stock records\nPlease try again"
    end
  end

  private

  def calculate_portfolio
    results = []
    multi_stock.transactions.order(:stock_id).group_by(&:stock).each do |stock, transactions|
      transactions = transactions.sort_by(&:date)
      portfolio_entry = { stock: stock.serialize }
      price = stock.stock_prices.where("date <= ?", multi_stock.end_date).order(date: :desc).first&.close_price || 0
      unsold_transactions = transactions.last.sell? ? [] : transactions.last.collect_unsold_between(include_self: true)
      total_quantity = unsold_transactions.sum(&:quantity)
      portfolio_entry[:invested_amount] = unsold_transactions.sum(&:amount)
      portfolio_entry[:final_shares] = unsold_transactions.sum(&:quantity)
      portfolio_entry[:portfolio] = (total_quantity * price)

      sold_transactions = transactions.select { |t| t.sell? && t.quantity > 0 }
      portfolio_entry[:pnl] = sold_transactions.present? ? ((transactions - unsold_transactions).sum { |t| t.sell? ? t.amount : -t.amount }) : 0

      portfolio_entry[:charges] = (transactions.sum(&:amount) * 0.003321) +  (sold_transactions.count * 16)
      results << portfolio_entry
    end
  results
  end

    def multi_stock
      @_multi_stock ||= MultiStock.find(params[:id])
    end

    def multi_stock_params
      params.require(:multi_stock).permit(:start_date, :end_date, :total_amount, :maximum_buy_amount, :investment_amount, :buy_dip_percentage, :sell_profit_percentage, :reinvestment_percentage, symbols: [], stock_ids: [])
    end

    def stock_symbols_params
      params.permit(stock_symbols: [], selected_ids: [])
    end

    def default_backtest_attributes
      last = MultiStock.last
      {
        start_date: last&.start_date || Date.current.beginning_of_month,
        end_date: last&.end_date || Date.today,
        investment_amount: last&.investment_amount&.to_i || 5000,
        maximum_buy_amount: last&.maximum_buy_amount&.to_i || 10000,
        sell_profit_percentage: last&.sell_profit_percentage&.to_i || 3,
        buy_dip_percentage: last&.buy_dip_percentage&.to_i || 6,
        reinvestment_percentage: last&.reinvestment_percentage&.to_i || 50,
        total_amount: last&.total_amount&.to_i || 200000
      }
    end
end
