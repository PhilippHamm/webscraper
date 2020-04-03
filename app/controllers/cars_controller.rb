require 'capybara'
require 'nokogiri'
require 'open-uri'
require 'capybara/dsl'
include Capybara::DSL
require 'csv'


class CarsController < ApplicationController
  def new
    @car = Car.new
  end

  def index
    @scraped_cars = Car.all
  end

  def create
    @car = Car.new
    cars = scraper(@car, car_params[:dealer_city])

    csv_options = { col_sep: ','}
    filepath    = Rails.root.join('lib', 'data', 'mobile.csv')

    CSV.open(filepath, 'wb', csv_options) do |csv|
      csv << ['Autoname', 'Preis', 'Kilometerstand', 'Hubraum', 'Leistung', 'Kraftstoff', 'Haendler', 'Postleitzahl', 'Stadt', 'Adresse', 'Telefon', 'Bewertung']
      cars.each do |car|
        csv << [car.carname.to_s, car.price.to_s, car.mileage.to_s, car.cubic_capacity.to_s, car.power.to_s, car.fuel.to_s, car.car_dealer.to_s, car.postal_code.to_s, car.city.to_s, car.address.to_s, car.phone.to_s, car.rating.to_s]
      end
    end
    raise
  end

  def destroy
  end


  # This is just for checking the form style of the dealer landing page, not relevant for scraper
  def form
  end

  private

  def car_params
    params.require(:car).permit(:dealer_city)
  end

  def scraper(car, city)

    #Setting capybara driver
    # Capybara.default_driver = :selenium_chrome # :selenium_chrome and :selenium_chrome_headless are also registered
    # Capybara.run_server = false
    # Capybara.app_host = 'https://www.mobile.de'
    # visit('https://www.mobile.de')
    # fill_in('ambit-search-location', with: city)
    # sleep(2)
    # find('#ambit-search-location').native.send_keys(:return)
    # sleep(1)
    # click_button("qssub")
    # sleep(1)
    cars = []
    i = 0
    j = 1

    unless i > 1
      q = all('.page-centered .viewport .g-row .g-col-9 .cBox--resultList .cBox-body--resultitem .result-item').map { |a| a['href'] }
      q.each do |ad|
        visit(ad)
        sleep(2)

        car.image_one = find('#rbt-gallery-img-1')
        raise
        car.image_two = images[1]
        car.image_three = images[2]
        car.image_four = images[3]
        car.image_five = images[4]
        car.image_six = images[5]
        raise
        if has_css?('#rbt-ad-title')
          car.title = find('#rbt-ad-title').text
        end
        if has_css?('#rbt-pt-v') == true
          car.price = find('#rbt-pt-v').text
        end
        if has_css?('rbt-damageCondition-v') == true
          car.damage_condition = find('rbt-damageCondition-v').text
        end
        if has_css?('rbt-category-v')
          car.category = find('rbt-category-v').text
        end
        if has_css?('#rbt-mileage-v')
          car.mileage = find('#rbt-mileage-v').text
        end
        if has_css?('#rbt-cubicCapacity-v')
          car.cubic_capacity = find('#rbt-cubicCapacity-v').text
        end
        if has_css?('#rbt-power-v')
          car.power = find('#rbt-power-v').text
        end
        if has_css?('#rbt-fuel-v')
          car.fuel = find('#rbt-fuel-v').text
        end
        if has_css?('rbt-envkv.emission-v')
          car.emission = find('rbt-envkv.emission-v').text
        end
        if has_css?('rbt-numSeats-v')
          car.num_seats = find('rbt-numSeats-v').text
        end
        if has_css?('rbt-doorCount-v')
          car.door_count = find('rbt-doorCount-v').text
        end
        if has_css?('rbt-transmission-v')
          car.transmission = find('rbt-transmission-v').text
        end
        if has_css?('rbt-emissionClass-v')
          car.emission_class = find('rbt-emissionClass-v').text
        end
        if has_css?('rbt-emissionsSticker-v')
          car.emssion_sticker = find('rbt-emissionsSticker-v').text
        end
        if has_css?('rbt-firstRegistration-v')
          car.first_registration = find('rbt-firstRegistration-v').text
        end
        # if has_css?()
        #   car.hu = find('').text
        # end
        if has_css?('rbt-climatisation-v')
          car.climatisation = find('rbt-climatisation-v').text
        end
        if has_css?('rbt-parkAssists-v')
          car.park_assist = find('rbt-parkAssists-v').text
        end
        if has_css?('rbt-airbag-v')
          car.airbag = find('rbt-airbag-v').text
        end
        # if has_css?()
        #   car.manufacturer_color_name = find('').text
        # end
        if has_css?('rbt-color-v')
          car.color = find('rbt-color-v').text
        end
        if has_css?('rbt-interior-v')
          car.interior = find('rbt-interior-v').text
        end
        # if has_css?()
        #   car.publishing_date = find('').texts
        # end
        car.dealer_name = find('#dealer-details-link-top .h3').text
        car.dealer_postal_code = find('#rbt-seller-address').text.match(/\d{5}/)
        car.dealer_city = find('#rbt-seller-address').text.match(/\w+(-| )?\w+$/)
        car.dealer_address = find('#rbt-seller-address').text.match(/^\D*\d*\w(-|,)?\w*/)
        car.dealer_phone = find('#rbt-seller-phone').text
        car.dealer_rating = find('#rbt-top-dealer-info .u-margin-bottom-9 .u-margin-top-9 .mde-rating .link--no-decoration .star-rating-s ')['data-rating']


        cars.push(car)
        i += 1
        break if i > 1
      end
      find('#srp-back-link').click
      j += 1
      find("#rbt-p-#{j}").click
    end
    return cars
  end
end
