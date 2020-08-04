class CreateCarDealers < ActiveRecord::Migration[5.2]
  def change
    create_table :car_dealers do |t|

      t.timestamps
    end
  end
end
