require 'capybara'
require 'nokogiri'
require 'open-uri'
require 'capybara/dsl'
include Capybara::DSL
require 'csv'

class CarDealersController < ApplicationController
  def new
    @car_dealer = CarDealer.new
  end

  def index
    @scraped_cars = CarDealer.all
  end

  def create
    @car_dealer = CarDealer.new
    cars = scraper(@car, car_params[:city])
  end

  def destroy
  end

  # This is just for checking the form style of the dealer landing page, not relevant for scraper
  def form
  end

  private
  def car_params
    params.require(:car_dealer).permit(:city)
  end

  def scraper(car, city)
    #Setting capybara driver
    Capybara.default_driver = :selenium_chrome # :selenium_chrome and :selenium_chrome_headless are also registered
    Capybara.run_server = false
    Capybara.app_host = 'https://www.mobile.de'
    Capybara.default_max_wait_time = 3
    Capybara.raise_server_errors = false

    visit('https://home.mobile.de/AH-SCHACHTSCHNEIDER#ses')

    sleep(2)
    # Code
    # Handle Error
    begin
      20.times {find('#ses > div.ses > div.moreResults > button > span').click}
    rescue Capybara::ElementNotFound
    rescue Selenium::WebDriver::Error::ElementNotInteractableError
    end
      cars = []
      q = []
      j = 0
      q = all('#ses > div.ses > ul > li').map { |a| a['id'] }
      q.each do |id|
          # visit car view page
          visit("https://home.mobile.de/AH-SCHACHTSCHNEIDER#des_#{id}")
          sleep(1)
          # create new hash car
          car = Hash.new
          begin
            # click on image
            find('#gallerySmall > div.galleryWrapper.desCarousel.image-gallery-wrapper > div.imageView.flexslider.mainImage > div > ul > li.slide.Small.flex-active-slide > div', visible:false).click
            # find all image links
            img = find('#galleryLarge > div > div.imageView.flexslider.mainImage.modalBox > div > ul').all('li div img', visible: false).map { |e| e['src'] }
            # assign all image links to hash
            i = 0
            img.each do |link|
              car["Bild_#{i}"] = link
              i += 1
            end
            find('#galleryLarge > div > div.imageView.flexslider.mainImage.modalBox > div > ul > li.slide.Large.flex-active-slide > div > img', visible: false).click
            # assign data to hash
            car["Kategorie"] = all('#des > div.des > div > div.vehicleMainInfo.right > div.vehicleAttributes > div.left > strong')[0].text
            car["Titel"] = find('#des > div.des > h3').text
            car["Preis"] = find('#des > div.des > div > div.vehicleMainInfo.right > div.vehiclePrice > strong').text.gsub(' Brutto', '')
            car["Herkunft"] = find('#des > div.des > div > div.vehicleMainInfo.right > div.vehicleAttributes > div.left > span.countryVersion').text
            begin
              car["Fahrzeugzustand"] = find('#des > div.des > div > div.vehicleMainInfo.right > div.vehicleAttributes > div.left > span.damaged').text
            rescue Capybara::ElementNotFound
            end
            attributes = find('#des > div.des > div > div.vehicleMainInfo.right > div.vehicleAttributes > div.left > span.attributes').text
            begin
              car["Erstzulassung"] = attributes.match(/\d{2}.\d{4}/)[0]
            rescue NoMethodError
            end
            car["Kilometerstand"] = attributes.match(/(\d*[.]\d{3}|\d*) km/)[0]
            car["Leistung"] = attributes.match(/\d*\skW\s.\d*\sPS./)[0]
            car["Kraftstoffart"] = attributes.match(/(Benzin|Diesel|Elektro)/)[0]
            car["Getriebe"] = attributes.match(/(Automatik|Schaltgetriebe)/)[0]
            car["Verbrauch"] = find('#des > div.des > div > div.vehicleTechDetails.row-fluid > dl.fuelConsumption.span10 > dd:nth-child(2)').text
            car["CO2-Emission"] = find('#des > div.des > div > div.vehicleTechDetails.row-fluid > dl.fuelConsumption.span10 > dd:nth-child(4)').text
            # get additional data from text field
            headline = all('#des > div.des > div > div.vehicleTechDetails.row-fluid > dl.additionalAttributes.span10 > dt').map { |a| a.text }
            data = all('#des > div.des > div > div.vehicleTechDetails.row-fluid > dl.additionalAttributes.span10 > dd').map { |a| a.text }
            # create additional data hash
            e = 0
            data_hash = Hash.new
            data.each do |datum|
              data_hash[headline[e]] = datum
              e += 1
            end
            # merge data and car hash
            car.merge!(data_hash)
            # get features
            features_1 = all('#des > div.des > div > div.vehicleFeatures.row-fluid > div:nth-child(2) > ul > li').map { |a| a.text }
            features_2 = all('#des > div.des > div > div.vehicleFeatures.row-fluid > div:nth-child(3) > ul > li').map { |a| a.text }
            features_3 = all('#des > div.des > div > div.vehicleFeatures.row-fluid > div:nth-child(4) > ul > li').map { |a| a.text }
            features_4 = all('#des > div.des > div > div.vehicleFeatures.row-fluid > div:nth-child(5) > ul > li').map { |a| a.text }
            features = features_1.concat(features_2).concat(features_3).concat(features_4)

            # Assign features separated by \n to hash
            car["Weitere Eigenschaften"] = features.join("\n")
            # assign link to hash
            car["Link"] = "https://home.mobile.de/AH-SCHACHTSCHNEIDER#des_#{id}"

            # Assign data for import sheet shopify
            car['Vendor'] = car['Titel'].match(/^[A-Za-z-]*/)
            car['Title'] = car['Titel'].gsub(/^[A-Za-z-]*/, '').gsub(/[+&\/.;,()']/, ' ')
            car['Body (HTML)'] = "<p>
                                  <strong>Fahrzeugzustand</strong>
                                  #{car['Fahrzeugzustand']}<br>
                                  <strong>Kategorie</strong>
                                  #{car['Kategorie']}<br>
                                  <strong>Herkunft</strong>
                                  #{car['Herkunft']}<br>
                                  <strong>Kilometerstand</strong>
                                  #{car['Kilometerstand']}<br>
                                  <strong>Hubraum</strong>
                                  #{car['Hubraum']}<br>
                                  <strong>Leistung</strong>
                                  #{car['Leistung']}<br>
                                  <strong>Kraftstoffart</strong>
                                  #{car['Kraftstoffart']}<br>
                                  <strong>Verbrauch</strong><br>
                                  #{car['Verbrauch']}<br>
                                  <strong>CO2-Emission</strong>
                                  #{car['CO2-Emission']}<br>
                                  <strong>Anzahl der Türen</strong>
                                  #{car['Anzahl der Türen']}<br>
                                  <strong>Anzahl Sitzplätze</strong>
                                  #{car['Anzahl Sitzplätze']}<br>
                                  <strong>Getriebe</strong>
                                  #{car['Getriebe']}<br>
                                  <strong>Schadstoffklasse</strong>
                                  #{car['Schadstoffklasse']}<br>
                                  <strong>Umweltplakette</strong>
                                  #{car['Umweltplakette']}<br>
                                  <strong>Erstzulassung</strong>
                                  #{car['Erstzulassung']}<br>
                                  <strong>Anzahl der Fahrzeughalter</strong>
                                  #{car['Anzahl der Fahrzeughalter']}<br>
                                  <strong>HU</strong>
                                  #{car['HU']}<br>
                                  <strong>Klimatisierung</strong>
                                  #{car['Klimatisierung']}<br>
                                  <strong>Farbe (Hersteller)</strong>
                                  #{car['Farbe (Hersteller)']}<br>
                                  <strong>Farbe</strong>
                                  #{car['Farbe']}<br>
                                  <strong>Innenausstattung</strong>
                                  #{car['Innenausstattung']}<br>
                                  <strong>Weitere Eigenschaften</strong><br>
                                  #{car['Weitere Eigenschaften']}
                                  </p>"

            # Create tags
            marke_tag = "Marke_#{car['Vendor']}"
            typ_tag = "Typ_#{car['Kategorie'].match(/^[SUV|Kleinwagen|Kombi|Sportwagen|Limousine]*/)[0]}"
            alter_jahr = (Date.today - Date.parse(car["Erstzulassung"])) / 365
            if alter_jahr < 2
              alter_tag = ["Alter_maximal 2 Jahre", "Alter_maximal 5 Jahre", "Alter_Alle"]
            elsif alter_jahr > 2 && alter_jahr < 5
              alter_tag = ["Alter_maximal 5 Jahre", "Alter_Alle"]
            else
              alter_tag = ["Alter_Alle"]
            end

            km_stand = car["Kilometerstand"].match(/[0-9]*/)[0]

            if km_stand.to_i < 20.000
              km_stand_tag = ["Kilometerstand_maximal 20.000 km", "Kilometerstand_maximal 50.000 km", "Kilometerstand_maximal 80.000 km", "Kilometerstand_maximal 100.000 km"]
            elsif km_stand.to_i < 50.000
              km_stand_tag = ["Kilometerstand_maximal 50.000 km", "Kilometerstand_maximal 80.000 km", "Kilometerstand_maximal 100.000 km"]
            elsif km_stand.to_i < 80.000
              km_stand_tag = ["Kilometerstand_maximal 80.000 km", "Kilometerstand_maximal 100.000 km"]
            elsif km_stand.to_i < 100.000
              km_stand_tag = ["Kilometerstand_maximal 100.000 km"]
            else
              km_stand_tag = ["Kilometerstand_Alle"]
            end

            leistung = car["Leistung"].match(/\d* PS/)[0].gsub('PS','')
            if leistung.to_i < 70
              leistung_tag = ['Leistung_bis 70 PS', 'Leistung_Alle']
            elsif leistung.to_i > 70 && leistung.to_i < 100
              leistung_tag = ['Leistung_70 bis 100 PS', 'Leistung_Alle']
            elsif leistung.to_i > 100 && leistung.to_i < 150
              leistung_tag = ['Leistung_100 bis 150 PS', 'Leistung_Alle']
            elsif leistung.to_i > 150 && leistung.to_i < 200
              leistung_tag = ['Leistung_150 bis 200 PS', 'Leistung_Alle']
            else
              leistung_tag = 'Leistung_Alle'
            end
            getriebe_tag = "Schaltung_#{car['Getriebe']}"
            farbe_tag = "Farbe_#{car['Farbe']}"
            kraftstoff_tag = "Kraftstoff_#{car['Kraftstoffart']}"
            zustand_tag = "Zustand_Gebraucht"
            # pricing arithmetic
            preis = "300"
            if preis.to_i < 200
              preis_tag = "Preis_Günstig (bis 200 €)"
            elsif preis.to_i > 200 && preis.to_i < 400
              preis_tag = "Preis_Mittel (200 bis 400 €)"
            elsif preis.to_i > 400
              preis_tag = "Preis_Premium (ab 400 €)"
            end
            # concat all tags
            car['Tags'] = "#{marke_tag}, #{typ_tag}, #{alter_tag}, #{km_stand_tag}, #{leistung_tag}, #{getriebe_tag}, #{farbe_tag}, #{kraftstoff_tag}, #{zustand_tag}, #{preis_tag}"
            cars.push(car)
            puts "total quantity #{cars.length}"
          rescue Capybara::ElementNotFound
          end
          j += 1
          break if j > 5
      end

      # find all car characteristics
      all_cars = Hash.new
      cars.each do |car|
        all_cars.merge!(car)
      end

      # build array with all hash keys
      header_array = all_cars.keys
      # header_string = header_array.join(',')

      # open csv file
      csv_options = { col_sep: ',' }
      filepath    = Rails.root.join('lib', 'data', 'schachtschneider.csv')
      # write headline csv
      CSV.open(filepath, 'wb', csv_options) do |csv|
        csv << [
          'Handle',
          'Title',
          'Body (HTML)',
          'Vendor',
          'Type',
          'Tags',
          'Published',
          'Option1 Name',
          'Option1 Value',
          'Option2 Name',
          'Option2 Value',
          'Option3 Name',
          'Option3 Value',
          'Variant SKU',
          'Variant Grams',
          'Variant Inventory Tracker',
          'Variant Inventory Qty',
          'Variant Inventory Policy',
          'Variant Fulfillment Service',
          'Variant Price',
          'Variant Compare At Price',
          'Variant Requires Shipping',
          'Variant Taxable',
          'Variant Barcode',
          'Image Src',
          'Image Position',
          'Image Src',
          'Image Position',
          'Image Src',
          'Image Position',
          'Image Src',
          'Image Position',
          'Image Src',
          'Image Position',
          'Image Src',
          'Image Position',
          'Image Src',
          'Image Position',
          'Image Src',
          'Image Position',
          'Image Src',
          'Image Position',
          'Image Src',
          'Image Position',
          'Image Src',
          'Image Position',
          'Image Alt Text',
          'Gift Card','SEO Title','SEO Description','Google Shopping / Google Product Category','Google Shopping / Gender','Google Shopping / Age Group','Google Shopping / MPN','Google Shopping / AdWords Grouping','Google Shopping / AdWords Labels','Google Shopping / Condition','Google Shopping / Custom Product','Google Shopping / Custom Label 0','Google Shopping / Custom Label 1','Google Shopping / Custom Label 2','Google Shopping / Custom Label 3','Google Shopping / Custom Label 4','Variant Image','Variant Weight Unit','Variant Tax Code','Cost per item'
        ]
      end
      CSV.open(filepath, 'a', csv_options) do |csv|
        cars.each do |car|
          csv << [
            car[header_array[0]],
            car[header_array[1]],
            car[header_array[2]],
            car[header_array[3]],
            car[header_array[4]],
            car[header_array[5]],
            car[header_array[6]],
            car[header_array[7]],
            car[header_array[8]],
            car[header_array[9]],
            car[header_array[10]],
            car[header_array[11]],
            car[header_array[12]],
            car[header_array[13]],
            car[header_array[14]],
            car[header_array[15]],
            car[header_array[16]],
            car[header_array[17]],
            car[header_array[18]],
            car[header_array[19]],
            car[header_array[20]],
            car[header_array[21]],
            car[header_array[22]],
            car[header_array[23]],
            car[header_array[24]],
            car[header_array[25]],
            car[header_array[26]],
            car[header_array[27]],
            car[header_array[28]],
            car[header_array[29]],
            car[header_array[30]],
            car[header_array[31]],
            car[header_array[32]],
            car[header_array[33]],
            car[header_array[34]],
            car[header_array[35]],
            car[header_array[36]],
            car[header_array[37]],
            car[header_array[38]],
            car[header_array[39]],
            car[header_array[40]],
            car[header_array[41]],
            car[header_array[42]],
            car[header_array[43]],
            car[header_array[44]],
            car[header_array[45]],
            car[header_array[46]]
          ]
        end
      end
      # open csv file
      csv_options = { col_sep: ',' }
      filepath    = Rails.root.join('lib', 'data', 'schachtschneider.csv')
      # write headline csv
      CSV.open(filepath, 'wb', csv_options) do |csv|
        csv << [
            header_array[0],
            header_array[1],
            header_array[2],
            header_array[3],
            header_array[4],
            header_array[5],
            header_array[6],
            header_array[7],
            header_array[8],
            header_array[9],
            header_array[10],
            header_array[11],
            header_array[12],
            header_array[13],
            header_array[14],
            header_array[15],
            header_array[16],
            header_array[17],
            header_array[18],
            header_array[19],
            header_array[20],
            header_array[21],
            header_array[22],
            header_array[23],
            header_array[24],
            header_array[25],
            header_array[26],
            header_array[27],
            header_array[28],
            header_array[29],
            header_array[30],
            header_array[31],
            header_array[32],
            header_array[33],
            header_array[34],
            header_array[35],
            header_array[36],
            header_array[37],
            header_array[38],
            header_array[39],
            header_array[40],
            header_array[41],
            header_array[42],
            header_array[43],
            header_array[44],
            header_array[45],
            header_array[46]
          ]

      end
      CSV.open(filepath, 'a', csv_options) do |csv|
        cars.each do |car|
          csv << [
            car[header_array[0]],
            car[header_array[1]],
            car[header_array[2]],
            car[header_array[3]],
            car[header_array[4]],
            car[header_array[5]],
            car[header_array[6]],
            car[header_array[7]],
            car[header_array[8]],
            car[header_array[9]],
            car[header_array[10]],
            car[header_array[11]],
            car[header_array[12]],
            car[header_array[13]],
            car[header_array[14]],
            car[header_array[15]],
            car[header_array[16]],
            car[header_array[17]],
            car[header_array[18]],
            car[header_array[19]],
            car[header_array[20]],
            car[header_array[21]],
            car[header_array[22]],
            car[header_array[23]],
            car[header_array[24]],
            car[header_array[25]],
            car[header_array[26]],
            car[header_array[27]],
            car[header_array[28]],
            car[header_array[29]],
            car[header_array[30]],
            car[header_array[31]],
            car[header_array[32]],
            car[header_array[33]],
            car[header_array[34]],
            car[header_array[35]],
            car[header_array[36]],
            car[header_array[37]],
            car[header_array[38]],
            car[header_array[39]],
            car[header_array[40]],
            car[header_array[41]],
            car[header_array[42]],
            car[header_array[43]],
            car[header_array[44]],
            car[header_array[45]],
            car[header_array[46]]
          ]
        end
      end
  end
end
