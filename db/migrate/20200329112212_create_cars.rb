class CreateCars < ActiveRecord::Migration[5.2]
  def change
    create_table :cars do |t|
      t.string :title
      t.string :price
      t.string :damage_condition
      t.string :category
      t.string :country_version
      t.string :consumption
      t.string :mileage
      t.string :cubic_capacity
      t.string :power
      t.string :fuel
      t.string :emission
      t.string :num_seats
      t.string :door_count
      t.string :transmission
      t.string :emission_class
      t.string :emssion_sticker
      t.string :first_registration
      t.string :hu
      t.string :climatisation
      t.string :park_assist
      t.string :airbag
      t.string :manufacturer_color_name
      t.string :color
      t.string :interior
      t.string :image_one
      t.string :image_two
      t.string :image_three
      t.string :image_four
      t.string :image_five
      t.string :image_six
      t.string :image_seven
      t.string :image_eight
      t.string :image_nine
      t.string :image_ten
      t.string :features
      t.string :dealer_name
      t.string :dealer_postal_code
      t.string :dealer_city
      t.string :dealer_address
      t.string :dealer_phone
      t.string :dealer_rating
      t.string :publishing_date

      t.timestamps
    end
  end
end
