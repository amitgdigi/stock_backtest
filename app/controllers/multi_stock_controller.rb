class MultiStockController < ApplicationController
  T_CHARGE = ENV.fetch("TRANSACTION_CHARGES_PERCENTAGE", 0.00223)
  CHARGE = ENV.fetch("SELLING_CHARGES_RUPEES", 16)

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

    stock_names = portfolio_data.map { |entry| entry[:stock][:ticker] }.join(", ")
    portfolio = portfolio_data.sum { |entry| entry[:portfolio] }
    pnl = portfolio_data.sum { |entry| entry[:pnl] }
    u_pnl = portfolio_data.sum { |entry| entry[:u_pnl] }
    u_pnl_per = portfolio_data.sum { |entry| entry[:u_pnl_per] }
    final_shares  = portfolio_data.sum { |entry| entry[:final_shares] }
    invested_amount  = portfolio_data.sum { |entry| entry[:invested_amount] }
    charges = portfolio_data.sum { |entry| entry[:charges] }
    charges_per = profit_percent(multi_stock.transactions, charges)
    pnl_per = profit_percent(multi_stock.transactions, pnl)
    first_transaction = multi_stock.transactions.order(:date, :id).first
    @multi_stock = multi_stock

    @result = {
      stock_names:,
      portfolio:,
      pnl:,
      u_pnl:,
      transactions: multi_stock.transactions.order(:date, :updated_at).map(&:serialize),
      final_shares:,
      invested_amount:,
      charges:,
      charges_per:,
      portfolio_data:,
      pnl_per:,
      u_pnl_per:,
      started: first_transaction.total_amount+first_transaction.amount+(first_transaction.amount*T_CHARGE.to_f),
      remains: multi_stock.total_amount,
      total_amount: multi_stock.total_amount+portfolio
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
      entry = { stock: stock.serialize }
      price = stock.stock_prices.where("date <= ?", multi_stock.end_date).order(date: :desc).first&.close_price || 0
      unsold_transactions = transactions.last.sell? ? [] : transactions.last.collect_unsold_between(include_self: true)
      entry[:invested_amount] = unsold_transactions.sum(&:amount)
      entry[:final_shares] = unsold_transactions.sum(&:quantity)
      entry[:portfolio] = (entry[:final_shares] * price)

      sold_transactions = transactions.select { |t| t.sell? && t.quantity > 0 }
      entry[:pnl] = sold_transactions.present? ? ((transactions - unsold_transactions).sum { |t| t.sell? ? t.amount : -t.amount }) : 0
      entry[:u_pnl] = (entry[:portfolio] - entry[:invested_amount]) || 0
      entry[:charges] = (transactions.sum { |t| t.amount * T_CHARGE.to_f }.round(2)) +  (sold_transactions.count * CHARGE.to_f)
      entry[:u_pnl_per]  = profit_percent(unsold_transactions, entry[:u_pnl]).round(2)
      entry[:pnl_per]  = profit_percent(transactions, entry[:pnl]).round(2)
      entry[:transactions] = transactions.map(&:serialize)
      results << entry
    end
  results
  end

  def profit_percent(t, pnl)
    return 0.0 if t.blank?

    min = t.sort_by(&:total_amount).first
    max = t.sort_by(&:total_amount).last
    min_amount = min.total_amount
    max_amount = (max.total_amount+max.amount).round
    investment = max_amount-min_amount
    pnl/investment*100
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
=begin
  <%# ======== existing====== %>
Add button to Toggle 
1.-----------------
  <% @result[:portfolio_data].each do |item| %>
    <% if item[:transactions].empty? %>
      <div class="text-gray-500 italic mb-6">No transactions recorded.</div>
    <% else %>
      <div class="overflow-x-auto shadow rounded-md">
        <table class="min-w-full divide-y border border-gray-200 divide-gray-200 bg-white rounded-md">
          <thead class="bg-gray-200">
            <tr>
              <th class="text-left px-4 py-2 text-sm font-semibold text-gray-600">Sr.</th>
              <th class="text-left px-4 py-2 text-sm font-semibold text-gray-600">Date</th>
              <th class="text-left px-4 py-2 text-sm font-semibold text-gray-600">Name</th>
              <th class="text-left px-4 py-2 text-sm font-semibold text-gray-600">Type</th>
              <th class="text-left px-4 py-2 text-sm font-semibold text-gray-600">Price</th>
              <th class="text-left px-4 py-2 text-sm font-semibold text-gray-600">Quantity</th>
              <th class="text-left px-4 py-2 text-sm font-semibold text-gray-600">Amount</th>
              <th class="text-left px-4 py-2 text-sm font-semibold text-gray-600">Remains</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-200 text-sm text-gray-700">
            <% item[:transactions].each_with_index do |txn, i| %>
              <tr class="hover:bg-gray-100 transition">
                <td class="px-4 py-2"><%= i+1 %></td>
                <td class="px-4 py-2"><%= txn[:date] %></td>
                <td class="px-4 py-2"><%= txn[:symbol] %></td>
                <td class="px-4 py-2 capitalize"><%= txn[:type] %></td>
                <td class="px-4 py-2"><%= txn[:price] %></td>
                <td class="px-8 py-2"><%= txn[:quantity] %></td>
                <td class="px-4 py-2">
                  <% amt = precision_inr(txn[:amount]) %>
                  <% if txn[:type] == "sell" %>
                    <span class="text-red-600 font-medium"><%= amt %></span>
                  <% else %>
                    <span class="text-green-700">-<%= amt %></span>
                  <% end %>
                </td>
                <td class="px-8 py-2"><%= txn[:remains] %></td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    <% end %>
  <% end %>
or
2.-------------------  
  <%# ======== existing====== %>
=end      
end
