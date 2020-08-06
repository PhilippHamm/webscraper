class DeleteCityFromCarDealers < ActiveRecord::Migration[5.2]
  def change
    remove_column :car_dealers, :city, :string
    add_column :car_dealers, :url_path, :string
  end
end
