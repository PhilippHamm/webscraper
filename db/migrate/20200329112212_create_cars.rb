class CreateCars < ActiveRecord::Migration[5.2]
  def change
    create_table :cars do |t|
      t.string :carname
      t.integer :price
      t.integer :mileage
      t.integer :cubic_capacity
      t.integer :power
      t.string :fuel
      t.string :car_dealer
      t.string :postal_code
      t.string :city
      t.string :address
      t.string :phone
      t.integer :rating
      t.string :publishing_date

      t.timestamps
    end
  end
end
