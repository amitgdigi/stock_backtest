class IpoStockController < ApplicationController
  T_CHARGE = ENV.fetch("TRANSACTION_CHARGES_PERCENTAGE", 0.00223).to_f
  CHARGE = ENV.fetch("SELLING_CHARGES_RUPEES", 16).to_f

  def index
    @stocks = Stock.none
    @ipo_stock = IpoStock.new(default_backtest_attributes)
  end

  def search_stock
    query = params[:q].to_s.strip
    stocks = Stock.where("ticker ILIKE ? OR name ILIKE ?", "%#{query}%", "%#{query}%").limit(20)
    if stocks.empty? && query.length > 2
      counter = Stock.last&.id || 0
      collect = SearchStockService.fetch_stock_search(query) || []
      stocks = collect.map do |c|
        counter += 1
        c.id = counter
        c
      end
    end

    render partial: "ipo_stock/stock_list", locals: { stocks: stocks }, formats: [ :html ]
  end

  def create
    selected_ids = params[:stock_ids] || []
    session[:selected_stocks] = selected_ids
    redirect_to ipo_stock_path(id: "result")
  end

  def show
    @ipo_stock = ipo_stock # ensure @ipo_stock is present before calculations
    portfolio_data = calculate_portfolio

    stock_names = portfolio_data.map { |entry| entry[:stock][:ticker] }.join(", ")
    portfolio = portfolio_data.sum { |entry| entry[:portfolio] }
    pnl = portfolio_data.sum { |entry| entry[:pnl] }
    u_pnl = portfolio_data.sum { |entry| entry[:u_pnl] }
    u_pnl_per = portfolio_data.sum { |entry| entry[:u_pnl_per] }
    final_shares = portfolio_data.sum { |entry| entry[:final_shares] }
    invested_amount = portfolio_data.sum { |entry| entry[:invested_amount] }
    charges = portfolio_data.sum { |entry| entry[:charges] }
    charges_per = profit_percent(ipo_stock.transactions, charges)
    pnl_per = profit_percent(ipo_stock.transactions, pnl)
    first_transaction = ipo_stock.transactions.order(:date, :id).first
    max_amount_invested = ipo_stock.transactions.order(:total_amount).first&.total_amount&.to_i

    @result = {
      stock_names:,
      portfolio:,
      pnl:,
      u_pnl:,
      transactions: ipo_stock.transactions.order(:date, total_amount: :desc).map(&:serialize),
      final_shares:,
      invested_amount:,
      charges:,
      charges_per:,
      portfolio_data:,
      pnl_per:,
      u_pnl_per:,
      max_amount_invested:,
      remains: ipo_stock.total_amount,
      total_amount: ipo_stock.total_amount + portfolio
    }
  end

  def backtest
    names = []
    names << [ "MON100", "AXISGOLD", "BSLGOLDETF", "HDFCSML250", "ITBEES", "ITETF", "ITIETF", "SBIETFIT" ] 
    names << [ "SBIETFIT" ] 
    names << [ "FMCGIETF", "NIFTYBEES", "MON100", "ITETF", "ITIETF", "AXISGOLD", "BSLGOLDETF", "HDFCSML250", "HDFCBSE500" ] 

    names = names.flatten.uniq
    stock_params = { "stock_symbols"=> names }

    service = ProcessIpoStockBacktestService.new(ipo_stock_params.merge(stock_params))

    result = service.run
    if result.is_a?(Hash) && result[:wait]
      return redirect_to ipo_stock_index_path, notice: "We are fetching missing stock data: #{result[:missing].join(', ')}. Please try again in a few minutes."
    end

    if result.is_a?(IpoStock)
      redirect_to ipo_stock_path(result.id)
    else
      redirect_to ipo_stock_index_path, alert: "Could not run IPO backtest. Missing data? We are fetching stock records. Please try again"
    end
  end

  private

  def calculate_portfolio
    results = []
    ipo_stock.transactions.order(:stock_id, :date, :id).group_by(&:stock).each do |stock, transactions|
      transactions = transactions.sort_by { |t| [t.date, t.id] }
      entry = { stock: stock.serialize }
      price = stock.stock_prices.where("date <= ?", ipo_stock.end_date).order(date: :desc).first&.close_price || 0
      unsold_transactions = transactions.last&.sell? ? [] : transactions.last&.collect_unsold_between(include_self: true) || []
      entry[:invested_amount] = unsold_transactions.sum(&:amount)
      entry[:final_shares] = unsold_transactions.sum(&:quantity)
      entry[:portfolio] = (entry[:final_shares] * price)

      sold_transactions = transactions.select { |t| t.sell? && t.quantity > 0 }
      entry[:pnl] = sold_transactions.present? ? ((transactions - unsold_transactions).sum { |t| t.sell? ? t.amount : -t.amount }) : 0
      entry[:u_pnl] = (entry[:portfolio] - entry[:invested_amount]) || 0
      entry[:charges] = (transactions.sum { |t| t.amount * T_CHARGE }.round(2)) + (sold_transactions.count * CHARGE)
      entry[:u_pnl_per] = profit_percent(unsold_transactions, entry[:u_pnl]).round(2)
      entry[:pnl_per] = profit_percent(transactions, entry[:pnl]).round(2)
      entry[:transactions] = transactions.map(&:serialize)
      results << entry
    end
    results
  end

  def profit_percent(t, pnl)
    return 0.0 if t.blank?

    min = t.min_by(&:total_amount)
    max = t.max_by(&:total_amount)
    min_amount = min.total_amount
    max_amount = (max.total_amount + max.amount).round
    investment = max_amount - min_amount
    return 0.0 if investment.zero?

    pnl / investment * 100
  end

  def ipo_stock
    @_ipo_stock ||= IpoStock.find(params[:id])
  end

  def ipo_stock_params
    params.require(:ipo_stock).permit(:start_date, :end_date, :total_amount, :maximum_buy_amount, :total_bought_amount_for_stock, :investment_amount, :buy_dip_percentage, :first_buy_percentage, :sell_profit_percentage, :reinvestment_percentage, symbols: [], stock_ids: [])
  end

  def stock_symbols_params
    params.permit(stock_symbols: [], selected_ids: [])
  end

  def default_backtest_attributes
    last = IpoStock.last
    {
      start_date: last&.start_date || Date.current.beginning_of_month,
      end_date: last&.end_date || Date.today,
      investment_amount: last&.investment_amount&.to_i || 5000,
      maximum_buy_amount: last&.maximum_buy_amount&.to_i || 10000,
      first_buy_percentage: last&.first_buy_percentage&.to_i || 10,
      buy_dip_percentage: last&.buy_dip_percentage&.to_i || 6,
      reinvestment_percentage: last&.reinvestment_percentage&.to_i || 50,
      sell_profit_percentage: last&.sell_profit_percentage&.to_i || 40,
      total_bought_amount_for_stock: last&.total_bought_amount_for_stock&.to_i || 30000
    }
  end
end
