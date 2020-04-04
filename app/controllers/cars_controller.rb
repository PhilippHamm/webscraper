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
    raise
    CSV.open(filepath, 'wb', csv_options) do |csv|
      csv << [
        'title',
        'price',
        'damage_condition',
        'category',
        'country_version',
        'consumption',
        'mileage',
        'cubic_capacity',
        'power',
        'fuel',
        'emission',
        'num_seats',
        'door_count',
        'transmission',
        'emission_class',
        'emssion_sticker',
        'first_registration',
        'hu',
        'climatisation',
        'park_assist',
        'airbag',
        'manufacturer_color_name',
        'color',
        'interior',
        'image_one',
        'image_two',
        'image_three',
        'image_four',
        'image_five',
        'image_six',
        'image_seven',
        'image_eight',
        'image_nine',
        'image_ten',
        'features',
        'dealer_name',
        'dealer_postal_code',
        'dealer_city',
        'dealer_address',
        'dealer_phone',
        'dealer_rating',
        'publishing_date'
      ]
      cars.each do |car|
        csv << [
          car.title,
          car.price,
          car.damage_condition,
          car.category,
          car.country_version,
          car.consumption,
          car.mileage,
          car.cubic_capacity,
          car.power,
          car.fuel,
          car.emission,
          car.num_seats,
          car.door_count,
          car.transmission,
          car.emission_class,
          car.emssion_sticker,
          car.first_registration,
          car.hu,
          car.climatisation,
          car.park_assist,
          car.airbag,
          car.manufacturer_color_name,
          car.color,
          car.interior,
          car.image_one,
          car.image_two,
          car.image_three,
          car.image_four,
          car.image_five,
          car.image_six,
          car.image_seven,
          car.image_eight,
          car.image_nine,
          car.image_ten,
          car.features,
          car.dealer_name,
          car.dealer_postal_code,
          car.dealer_city,
          car.dealer_address,
          car.dealer_phone,
          car.dealer_rating,
          car.publishing_date
        ]
      end
    end
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
    Capybara.default_driver = :selenium_chrome # :selenium_chrome and :selenium_chrome_headless are also registered
    Capybara.run_server = false
    Capybara.app_host = 'https://www.mobile.de'
    # visit('https://www.mobile.de')
    # fill_in('ambit-search-location', with: city)
    # sleep(2)
    # find('#ambit-search-location').native.send_keys(:return)
    # sleep(1)
    # click_button("qssub")
    # sleep(2)
    visit('https://suchen.mobile.de/fahrzeuge/search.html?adLimitation=ONLY_DEALER_ADS&categories=Cabrio&categories=EstateCar&categories=Limousine&categories=OffRoad&categories=SmallCar&categories=SportsCar&categories=Van&cn=DE&damageUnrepaired=NO_DAMAGE_UNREPAIRED&features=FULL_SERVICE_HISTORY&features=NONSMOKER_VEHICLE&features=WARRANTY&fuels=DIESEL&fuels=PETROL&gn=Berlin&isSearchRequest=true&ll=52.516071%2C13.37698&maxPowerAsArray=PS&minPowerAsArray=PS&rd=100&readyToDrive=ONLY_READY_TO_DRIVE&scopeId=C&sfmr=false&usage=USED&withImage=true')
    sleep(1)
    # Inseratdatum!!!!
    # visit("#{find('#so-sb > option:nth-child(9)')['data-url']}")
    cars = []
    i = 0
    j = 2

    until i > 2
      #z1234 > div.viewport > div > div:nth-child(3) > div:nth-child(4) > div.g-col-9 > div:nth-child(3) > div:nth-child(1) > a
      q = all('.page-centered .viewport .g-row .g-col-9 .cBox--resultList .cBox-body--resultitem .result-item').map { |a| a['href'] }

      # Inseratdatum
      # publishing_dates = all('#z1234 > div.viewport > div > div:nth-child(3) > div:nth-child(4) > div.g-col-9 > div:nth-child(3) > div.cBox-body.cBox-body--resultitem.dealerAd.rbt-reg.rbt-no-top > a > div > div.g-col-9 > div:nth-child(1) > div.g-col-8 > div > span.u-block.u-pad-top-9.rbt-onlineSince').map { |a| a.text }
      q.each do |ad|
        visit(ad)

        # Inseratdatum!!!!
        # car.publishing_date = publishing_dates[i]
        if has_css?('#rbt-envkv\.consumption-v > div.u-margin-bottom-9')
          consumptions = all('#rbt-envkv\.consumption-v > div.u-margin-bottom-9').map { |c| c.text }
          car.consumption = consumptions.join("*")
        end
        if has_css?('#z1234 > div.viewport > div > div:nth-child(2) > div:nth-child(5) > div.g-col-8 > div.cBox.cBox--content.cBox--vehicle-details.u-overflow-inherit.u-margin-top-225 > div:nth-child(2) > div > div.g-col-2 > div > div > div > div > div > div > div > div:nth-child(5)')
          find('#z1234 > div.viewport > div > div:nth-child(2) > div:nth-child(5) > div.g-col-8 > div.cBox.cBox--content.cBox--vehicle-details.u-overflow-inherit > div:nth-child(2) > div > div.g-col-2 > div > div > div > div > div > div > div > div:nth-child(2)').click
          car.image_two = all('#rbt-gallery-img-1 > img', visible: false).first['data-lazy']
          car.image_three = all('#rbt-gallery-img-2 > img', visible: false).first['data-lazy']
          car.image_four = all('#rbt-gallery-img-3 > img', visible: false).first['data-lazy']
          car.image_five = all('#rbt-gallery-img-4 > img', visible: false).first['data-lazy']
          car.image_six = all('#rbt-gallery-img-5 > img', visible: false).first['data-lazy']
          find('#standard-overlay-image-gallery-container > div:nth-child(2) > div > div > span').click
        end
        # if has_css?('#rbt-gallery-img-1 > img')
        # end
        # if has_css?('#rbt-gallery-img-2 > img')
        #   car.image_three = all('#rbt-gallery-img-2 > img', visible: false).first['data-lazy']
        # end
        # if has_css?('#rbt-gallery-img-3 > img')
        # end
        # if has_css?('#rbt-gallery-img-4 > img')
        # end
        # if has_css?('#rbt-gallery-img-5 > img')
        # end


        car.title = find('#rbt-ad-title').text
        car.price = find('#rbt-pt-v').text
        if has_css?('#rbt-damageCondition-v')
          car.damage_condition = find('#rbt-damageCondition-v').text
        end
        if has_css?('#rbt-category-v')
          car.category = find('#rbt-category-v').text
        end
        car.mileage = find('#rbt-mileage-v').text
        if has_css?('#rbt-cubicCapacity-v')
          car.cubic_capacity = find('#rbt-cubicCapacity-v').text
        end
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
        if has_css?('#rbt-hu-v')
          car.hu = find('#rbt-hu-v').text
        end
        if has_css?('#rbt-climatisation-v')
          car.climatisation = find('#rbt-climatisation-v').text
        end
        if has_css?('#rbt-parkAssists-v')
          car.park_assist = find('#rbt-parkAssists-v').text
        end
        if has_css?('#rbt-airbag-v')
          car.airbag = find('#rbt-airbag-v').text
        end
        if has_css?('#rbt-manufacturerColorName-v')
          car.manufacturer_color_name = find('#rbt-manufacturerColorName-v').text
        end
        if has_css?('#rbt-color-v')
          car.color = find('#rbt-color-v').text
        end

        if has_css?('#rbt-interior-v')
          car.interior = find('#rbt-interior-v').text
        end
        car.dealer_name = find('#dealer-details-link-top > h4').text
        car.dealer_postal_code = find('#rbt-seller-address').text.match(/\d{5}/)
        car.dealer_city = find('#rbt-seller-address').text.match(/\w+(-| )?\w+$/)
        car.dealer_address = find('#rbt-seller-address').text.match(/^\D*\d*\w(-|,)?\w*/)
        car.dealer_phone = find('#rbt-seller-phone').text
        car.dealer_rating = find('#rbt-top-dealer-info > div > div > span > a > span.star-rating-s.u-valign-middle.u-margin-right-9')['data-rating']
        features = all('#rbt-features > div > div.g-col-6 > div.bullet-list > p').map { |p| p.text }
        car.features = features.join("*")





        cars.push(car)
        i += 1



        if i == 2
          raise
        end
        break if i > 2
      end

      raise
      find('#srp-back-link').click
      sleep(2)
      find("#rbt-p-#{j}").click
      j += 1
      sleep(1)
    end
    return cars
  end
end
