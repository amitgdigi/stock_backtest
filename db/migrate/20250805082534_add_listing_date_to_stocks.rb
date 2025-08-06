class AddListingDateToStocks < ActiveRecord::Migration[8.0]
  def change
    add_column :stocks, :listing_date, :date
  end
end
