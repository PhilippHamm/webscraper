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
        # images = all('#standard-overlay-image-gallery-container .g-row .g-col-12 .image-gallery-wrapper .overlay-image-gallery .slick-image-gallery-wrapper .image-gallery-wrapper .image-gallery .gallery .slick-list .slick-track .slick-slide .cycle-slideshow .cycle-slide').map { |e| e['src'] }
        #.map { |e| e['src'] }
        find('#z1234 > div.viewport > div > div:nth-child(2) > div:nth-child(5) > div.g-col-8 > div.cBox.cBox--content.cBox--vehicle-details.u-overflow-inherit > div:nth-child(2) > div > div.g-col-2 > div > div > div > div > div > div > div > div:nth-child(2)').click
        car.image_one = find('#rbt-gallery-img-0 > img')['src']
        car.image_two = all('#rbt-gallery-img-1 > img', visible: false).first['data-lazy']
        car.image_three = all('#rbt-gallery-img-2 > img', visible: false).first['data-lazy']
        car.image_four = all('#rbt-gallery-img-3 > img', visible: false).first['data-lazy']
        car.image_five = all('#rbt-gallery-img-4 > img', visible: false).first['data-lazy']
        car.image_six = all('#rbt-gallery-img-5 > img', visible: false).first['data-lazy']
        find('#standard-overlay-image-gallery-container > div:nth-child(2) > div > div > span').click
        car.title = find('#rbt-ad-title').text
        car.price = find('#rbt-pt-v').text
        if has_css?('#rbt-damageCondition-v')
          car.damage_condition = find('#rbt-damageCondition-v').text
        end
        if has_css?('#rbt-category-v')
          car.category = find('#rbt-category-v').text
        end
        car.mileage = find('#rbt-mileage-v').text
        car.cubic_capacity = find('#rbt-cubicCapacity-v').text
        car.power = find('#rbt-power-v').text
        car.fuel = find('#rbt-fuel-v').text
        if has_css?('#rbt-envkv.emission-v')
          car.emission = find('#rbt-envkv.emission-v').text
        end
        if has_css?('#rbt-numSeats-v')
          car.num_seats = find('#rbt-numSeats-v').text
        end
        if has_css?('#rbt-doorCount-v')
          car.door_count = find('#rbt-doorCount-v').text
        end
        if has_css?('#rbt-transmission-v')
          car.transmission = find('#rbt-transmission-v').text
        end
        if has_css?('#rbt-emissionClass-v')
          car.emission_class = find('#rbt-emissionClass-v').text
        end
        if has_css?('#rbt-emissionsSticker-v')
          car.emssion_sticker = find('#rbt-emissionsSticker-v').text
        end
        if has_css?('#rbt-firstRegistration-v')
          car.first_registration = find('#rbt-firstRegistration-v').text
        end
        # if has_css?()
        #   car.hu = find('').text
        # end
        if has_css?('#rbt-climatisation-v')
          car.climatisation = find('#rbt-climatisation-v').text
        end
        if has_css?('#rbt-parkAssists-v')
          car.park_assist = find('#rbt-parkAssists-v').text
        end
        if has_css?('#rbt-airbag-v')
          car.airbag = find('#rbt-airbag-v').text
        end
        # if has_css?()
        #   car.manufacturer_color_name = find('').text
        # end
        if has_css?('#rbt-color-v')
          car.color = find('#rbt-color-v').text
        end
        if has_css?('#rbt-interior-v')
          car.interior = find('#rbt-interior-v').text
        end
        # if has_css?()
        #   car.publishing_date = find('').texts
        # end
        car.dealer_name = find('#dealer-details-link-top > h4').text
        car.dealer_postal_code = find('#rbt-seller-address').text.match(/\d{5}/)
        car.dealer_city = find('#rbt-seller-address').text.match(/\w+(-| )?\w+$/)
        car.dealer_address = find('#rbt-seller-address').text.match(/^\D*\d*\w(-|,)?\w*/)
        car.dealer_phone = find('#rbt-seller-phone').text
        car.dealer_rating = find('#rbt-top-dealer-info > div > div > span > a > span.star-rating-s.u-valign-middle.u-margin-right-9')['data-rating']

        features = all('#rbt-features > div > div.g-col-6 > div.bullet-list > p').map { |p| p.text }

        raise
        cars.push(car)
        i += 1
        break if i >= 1
      end
      raise
      find('#srp-back-link').click
      j += 1
      find("#rbt-p-#{j}").click
    end
    return cars
  end
end
