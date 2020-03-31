require 'capybara'
require 'nokogiri'
require 'open-uri'
require 'capybara/dsl'
include Capybara::DSL


class CarsController < ApplicationController
  def new
    @car = Car.new
  end

  def index
    @scraped_cars = Car.all
  end

  def create
    scraper(car_params[:city])
  end

  def destroy
  end

  private

  def car_params
    params.require(:car).permit(:city)
  end

  def scraper(city)

    # Setting capybara driver
    Capybara.default_driver = :selenium_chrome # :selenium_chrome and :selenium_chrome_headless are also registered
    Capybara.run_server = false
    Capybara.app_host = 'https://www.mobile.de'
    visit('https://www.mobile.de')
    fill_in('ambit-search-location', with: 'Berlin')
    click_button("qssub")
    find_link('link--muted no--text--decoration result-item').click
    q = find('h3 rbt-prime-price').content



    raise
    start_url = URI.parse(current_url)
    doc = Nokogiri::HTML(open(start_url))
    doc.css('slick-slide slick-active reco-item', 'mde-vehicle-card', 'mde-vehicle-card__price').each do |link|
      @price = link.content
    end
  end
end




