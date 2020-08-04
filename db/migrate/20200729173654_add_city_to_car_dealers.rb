class AddCityToCarDealers < ActiveRecord::Migration[5.2]
  def change
    add_column :car_dealers, :city, :string
  end
end
