require 'capybara'
require 'nokogiri'
require 'open-uri'
require 'capybara/dsl'
include Capybara::DSL
require 'csv'
require 'pry-byebug'

class CarDealersController < ApplicationController
  def new
    @car_dealer = CarDealer.new
  end

  def index
    @scraped_cars = CarDealer.all
  end

  def create
    @car_dealer = CarDealer.new
    # Calling the scraper function
    scraper(car_params[:url_path])
  end

  private
  def car_params
    params.require(:car_dealer).permit(:url_path)
  end

  def scraper(url_path)
    # Assign dealer url from given url_path
    dealer_url = url_path.gsub('https://home.mobile.de/', '').gsub('#ses', '')

    # open csv file
    csv_options = { col_sep: ',' }

    # Name and path of file
    filepath    = Rails.root.join('lib', 'data', "#{DateTime.now.strftime("%Y-%m-%d-%k:%M")}_#{dealer_url}.csv")

    # Write headline for csv file
    # First four headlines are not relevant for shopify and serve as dealer reference
    # Before starting shopify import the first 4 columns must be deleted
    CSV.open(filepath, 'wb', csv_options) do |csv|
      csv << [
        'Dealer name',
        'Dealer adress',
        'Purchase price',
        'Reselling price',
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

    # Setting capybara driver, which mimics user behaviour
    Capybara.default_driver = :selenium_chrome # :selenium_chrome and :selenium_chrome_headless are also registered
    Capybara.run_server = false
    Capybara.app_host = 'https://www.mobile.de'
    Capybara.default_max_wait_time = 3
    Capybara.raise_server_errors = false

    # =====> begin, rescue, end keep the programm going, even mobile.de produces
    # some unforeseeable frontend glitches

    begin
      visit(url_path)
    rescue Net::ReadTimeout
    end
    sleep(2)
    begin
      # Clicks on "Weitere Angebote"
      20.times {find('#ses > div.ses > div.moreResults > button > span').click}
    rescue Capybara::ElementNotFound
    rescue Selenium::WebDriver::Error::ElementNotInteractableError
    end

    # Set later used variables
    cars = []
    q = []
    j = 0
    p = 0

    # Get all ad id's
    q = all('#ses > div.ses > ul > li').map { |a| a['id'] }

    # Loops over Ad ID's
    q.each do |id|
      # visit car view page
      visit("https://home.mobile.de/#{dealer_url}#des_#{id}")
      sleep(1)

      # create new hash car
      car = Hash.new

      begin
        # Get headline data of ad
        attributes = find('#des > div.des > div > div.vehicleMainInfo.right > div.vehicleAttributes > div.left > span.attributes').text

        # Assign headline data
        car["Kilometerstand"] = attributes.match(/(\d*[.]\d{3}|\d*) km/)[0]
        car["Leistung"] = attributes.match(/\d*\skW\s.\d*\sPS./)[0]
        car["Kraftstoffart"] = attributes.match(/(Benzin|Diesel|Elektro|Erdgas)/)[0]
        car["Preis"] = find('#des > div.des > div > div.vehicleMainInfo.right > div.vehiclePrice > strong').text.gsub(' Brutto', '')
        car["Kategorie"] = all('#des > div.des > div > div.vehicleMainInfo.right > div.vehicleAttributes > div.left > strong')[0].text
        begin
          car["Erstzulassung"] = attributes.match(/\d{2}.\d{4}/)[0]
        rescue NoMethodError
        end

        # Format data for ADA requirement check
        km_stand = car["Kilometerstand"].gsub(/[^\d]/,'').to_i
        power = car["Leistung"].match(/^\d*/)[0].to_i
        price = car["Preis"].gsub(/[^\d]/,'').to_i

        # !!!!!!!!!!!!!!!!!!!!!!!
        # Check if the car fulfils ADA requirements
        if  km_stand < 60000 && km_stand > 1000 && price < 30000 && power < 210 &&
            car["Kraftstoffart"].match?(/(Diesel|Benzin)/) &&
            car["Kategorie"].match?(/(SUV|Kleinwagen|Kombi|Sportwagen|Limousine)/)

          # click on image
          find('#sliderSmall > div.sliderDiv.es-carousel > ul > li:nth-child(2) > div > a > img').click
          begin
            find('#gallerySmall > div.galleryWrapper.desCarousel.image-gallery-wrapper > div.imageView.flexslider.mainImage > div > ul > li.slide.Small.flex-active-slide > div', visible:false).click
          rescue Selenium::WebDriver::Error::ElementNotInteractableError
            puts "ElementNotInteractableError"
            find('#sliderSmall > div.sliderDiv.es-carousel > ul > li:nth-child(3) > div > a > img').click
            find('#gallerySmall > div.galleryWrapper.desCarousel.image-gallery-wrapper > div.imageView.flexslider.mainImage > div > ul > li.slide.Small.flex-active-slide > div', visible:false).click
          end

          # Find all image links
          img = find('#galleryLarge > div > div.imageView.flexslider.mainImage.modalBox > div > ul').all('li div img', visible: false).map { |e| e['src'] }

          # Assign all image links to hash
          i = 0
          img.each do |link|

            # Replace strings to select higher resolution pictures
            link.gsub!('$_27.jpg','$_57.jpg')
            car["Bild_#{i}"] = link
            i += 1
          end

          # Image position holder csv
          j = 0
          # !!!!!!!! If quantitiy of pictures to be changed
          23.times do
            if car["Bild_#{j}"]
              car["Bild_index_#{j}"] = j
              j += 1
            end
          end

          # Closes image carsousel
          begin
            find('#galleryLarge > div > div.imageView.flexslider.mainImage.modalBox > div > ul > li.slide.Large.flex-active-slide > div > img', visible: false).click
          rescue  Selenium::WebDriver::Error::ElementNotInteractableError
            sleep(3)
            find('#galleryLarge > div > div.imageView.flexslider.mainImage.modalBox > div > ul > li.slide.Large.flex-active-slide > div > img', visible: false).click
          end

          # Assign data to hash
          car["Titel"] = find('#des > div.des > h3').text
          begin
            car["Fahrzeugzustand"] = find('#des > div.des > div > div.vehicleMainInfo.right > div.vehicleAttributes > div.left > span.damaged').text
          rescue Capybara::ElementNotFound
          end
          begin
            car["Herkunft"] = find('#des > div.des > div > div.vehicleMainInfo.right > div.vehicleAttributes > div.left > span.countryVersion').text
          rescue Capybara::ElementNotFound
          end

          car["Getriebe"] = attributes.match(/(Automatik|Schaltgetriebe)/)[0]
          begin
            car["Verbrauch"] = find('#des > div.des > div > div.vehicleTechDetails.row-fluid > dl.fuelConsumption.span10 > dd:nth-child(2)').text.gsub(')',')<br>')
          rescue Capybara::ElementNotFound
          end
          begin
            car["CO2-Emission"] = find('#des > div.des > div > div.vehicleTechDetails.row-fluid > dl.fuelConsumption.span10 > dd:nth-child(4)').text
          rescue Capybara::ElementNotFound
          end

          # Get additional data from text field
          headline = all('#des > div.des > div > div.vehicleTechDetails.row-fluid > dl.additionalAttributes.span10 > dt').map { |a| a.text }
          data = all('#des > div.des > div > div.vehicleTechDetails.row-fluid > dl.additionalAttributes.span10 > dd').map { |a| a.text }

          # Create additional data hash
          e = 0
          data_hash = Hash.new
          data.each do |datum|
            data_hash[headline[e]] = datum
            e += 1
          end

          # Merge data and car hash
          car.merge!(data_hash)

          # Get features
          features_1 = all('#des > div.des > div > div.vehicleFeatures.row-fluid > div:nth-child(2) > ul > li').map { |a| a.text }
          features_2 = all('#des > div.des > div > div.vehicleFeatures.row-fluid > div:nth-child(3) > ul > li').map { |a| a.text }
          features_3 = all('#des > div.des > div > div.vehicleFeatures.row-fluid > div:nth-child(4) > ul > li').map { |a| a.text }
          features_4 = all('#des > div.des > div > div.vehicleFeatures.row-fluid > div:nth-child(5) > ul > li').map { |a| a.text }
          features = features_1.concat(features_2).concat(features_3).concat(features_4)

          # Assign features separated by \n to hash
          car["Weitere Eigenschaften"] = features.join(", ")

          # Assign link to car hash
          car["Link"] = "https://home.mobile.de/AH-SCHACHTSCHNEIDER#des_#{id}"

          # Assign data for import sheet shopify
          car['Vendor'] = car['Titel'].match(/^[A-Za-z-ë]*/)[0]
          car['Title'] = car['Titel'].gsub(/[+&\/*;,()'_]/, ' ')
          car['Handle'] = "#{car['Title'].gsub(/\s/,'-')}"
          car['Dealer'] = find('#container > footer > div > div > div:nth-child(3) > address > strong').text
          car['Pickup_location'] = find('#container > footer > div > div > div:nth-child(3) > address > div.span12.addressData').text

          # Assign data for Shopify description field
          # !!!!!!!!!!!!!! To be changed for frontend changes (fe wording)
          car['Body (HTML)'] =
"<p>
<strong>Abholadresse</strong>
#{car['Pickup_location']}<br>
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
#{car['Verbrauch']}
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

          # !!!!!!!!!!!!!!!!!!!!!! Filter boxes in Shopify
          # Create and assign Shopify tags
          marke_tag = "Marke_#{car['Vendor']}"
          typ_tag = "Typ_#{car['Kategorie'].match(/^[SUV|Kleinwagen|Kombi|Sportwagen|Limousine]*/)[0]}"
          begin
            alter_jahr = (Date.today - Date.parse(car["Erstzulassung"])) / 365
            if alter_jahr < 2
              alter_tag = ["Alter_maximal 2 Jahre", "Alter_maximal 5 Jahre", "Alter_Alle"]
            elsif alter_jahr > 2 && alter_jahr < 5
              alter_tag = ["Alter_maximal 5 Jahre", "Alter_Alle"]
            else
              alter_tag = ["Alter_Alle"]
            end
          rescue TypeError
            alter_tag = ["Alter_Alle"]
          end

          # Mileage tag
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

          # power tag
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
            leistung_tag = ['Leistung_Alle']
          end

          # transmission tag
          getriebe_tag = "Schaltung_#{car['Getriebe']}"
          if car['Farbe'].nil?
            farbe_tag = 'Farbe_Alle'
          else
            farbe_tag = "Farbe_#{car['Farbe'].match(/^[A-Za-zäöüß]*/)[0]}"
          end
          kraftstoff_tag = "Kraftstoff_#{car['Kraftstoffart']}"
          zustand_tag = "Zustand_Gebraucht"

          # !!!!!!!!!!!!!!!!!!!!
          # Call function pricing to create prices acc. to pricing mecanic
          abo_preise = pricing(car['Preis'].gsub(/[^\d]/, '').to_i, leistung.to_i,
                               car['Hubraum'].gsub(/[^\d]/, '').to_i,
                               car['Kraftstoffart'], car['CO2-Emission'].gsub(/[^\d]/, '').to_i)
          car.merge!(abo_preise)

          # Assign Shopify price tags
          if car['preis_12_s'] <= 200
            preis_tag = "Preis_Günstig (bis 200 €)"
          elsif car['preis_12_s'] > 200 && abo_preise['preis_12_s'] <= 400
            preis_tag = "Preis_Mittel (200 bis 400 €)"
          elsif car['preis_12_s'] > 400
            preis_tag = "Preis_Premium (ab 400 €)"
          end

          # Call reselling function to assign dealer reselling prices
          reselling = reselling_prices(car['Preis'].gsub(/[^\d]/, '').to_i)

          # Concat all tags
          car['Tags'] = "#{marke_tag}, #{typ_tag}, #{alter_tag.join(',')}, #{km_stand_tag.join(',')}, #{leistung_tag.join(',')}, #{getriebe_tag}, #{farbe_tag}, #{kraftstoff_tag}, #{zustand_tag}, #{preis_tag}"

          # !!!!!!!!!!! Relevant for frontend changes
          # Write first line of each car in csv file
          CSV.open(filepath, 'a', csv_options) do |csv|
            csv << [
              car['Dealer'],
              car['Pickup_location'],
              car['Preis'].gsub(/[^\d]/, '').to_i,
              reselling['3_s'],
              car['Handle'],
              car['Title'],
              car['Body (HTML)'],
              car['Vendor'],
              nil,
              car['Tags'],
              'WAHR',
              'Deine Abo Dauer',
              '3 Monate',
              'Dein monatliches Kilometerpaket',
              '500 km',
              nil,
              nil,
              'ADA',
              '0',
              nil,
              '0',
              'deny',
              'manual',
              car['preis_3_s'],
              nil,
              'FALSCH',
              'WAHR',
              nil,
              car['Bild_1'],
              car['Bild_index_1'],
              car['Bild_2'],
              car['Bild_index_2'],
              car['Bild_3'],
              car['Bild_index_3'],
              car['Bild_4'],
              car['Bild_index_4'],
              car['Bild_5'],
              car['Bild_index_5'],
              car['Bild_6'],
              car['Bild_index_6'],
              car['Bild_7'],
              car['Bild_index_7'],
              car['Bild_8'],
              car['Bild_index_8'],
              car['Bild_9'],
              car['Bild_index_9'],
              car['Bild_10'],
              car['Bild_index_10'],
              car['Bild_11'],
              car['Bild_index_11'],
              car['Bild_12'],
              car['Bild_index_12'],
              car['Bild_13'],
              car['Bild_index_13'],
              car['Bild_14'],
              car['Bild_index_14'],
              car['Bild_15'],
              car['Bild_index_15'],
              car['Bild_16'],
              car['Bild_index_16'],
              car['Bild_17'],
              car['Bild_index_17'],
              car['Bild_18'],
              car['Bild_index_18'],
              car['Bild_19'],
              car['Bild_index_19'],
              car['Bild_20'],
              car['Bild_index_20'],
              car['Bild_21'],
              car['Bild_index_21']
            ]
            # Define hash to assign package name to km
            package_hash = {  's'   => '500 km',
                              'm'   => '1000 km',
                              'l'   => '1500 km',
                              'xl'  => '2000 km',
                              'xxl' => '2500 km'
                            }

            # Assign remaining csv rows for 3 months
            for package in ['m', 'l', 'xl', 'xxl'] do
              csv << [nil, nil, nil, reselling["3_#{package}"], car['Handle'],
                      nil, nil, nil, nil, nil, nil, nil, '3 Monate', nil,
                      package_hash[package], nil, nil, 'ADA', '0', nil, '0',
                      'deny', 'manual', car["preis_3_#{package}"], nil,
                      'FALSCH', 'WAHR']
            end

            # Write all remaining rows into csv
            for duration in 4..12 do
              for package in ['m', 'l', 'xl', 'xxl'] do
                csv << [nil, nil, nil, reselling["#{duration}_#{package}"],
                        car['Handle'], nil, nil, nil, nil, nil, nil, nil,
                        "#{duration} Monate", nil, package_hash[package],
                        nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual',
                        car["preis_#{duration}_#{package}"],
                        nil, 'FALSCH', 'WAHR']
              end
            end
          end
          # # Uncomment to limit number of scraped ads
          # p += 1
          # break if p > 6
        end

      rescue TypeError
        puts "TypeError"
      rescue Selenium::WebDriver::Error::StaleElementReferenceError
        puts "StaleElementReferenceError"
      rescue NoMethodError
        puts "NoMethodError"
      rescue Capybara::ElementNotFound
        puts "Capybara::ElementNotFound"
      end
    end
  end

  def pricing(selling_price_gross, power, cubic_cap, fuel_type, emission)
    # =============> The pricing function determines prices for all
    # mileage / duration combinations

    # Assign all constants
    # All costs in net euro

    # ADA margin (percentage)
    margin = 10.0 / 100

    # Taxes
    vat = 16.0 / 100
    insur_vat = 19.0 / 100
    # emission tax per g above 95
    emis_tax_month = 2.0 / 12
    tolerance_emis = 95.0
    diesel_tax_month = 9.5 / 12
    benzin_tax_month = 2.0 / 12
    gez_month = 5.38 / (1 + vat)

    # Selling price
    selling_price = selling_price_gross / (1.0 + vat)

    # non-recurring costs
    ada_setup_cost = 100.0
    registration = 100.0 / (1 + vat)

    # only occurs every 10000 km
    maintenance = 100.0 / (1 + vat)
    maintenance_fee = 0

    # general inspection TUEV month
    gen_inspection = 100.0 / 12 / (1 + vat)

    # recurring costs
    loan_interest_year = 5.0 / 100
    loan_cost_month = loan_interest_year * selling_price_gross / 12
    warranty_month = 170.0 / 12 / (1 + vat)

    # payment provider
    transaction_fee = 0.06 / (1 + vat)
    solvency_fee = 0.45 / (1 + vat)
    payment_share = 3.0 / 1000

    # insurance
    power_kw = power / 1.36
    if power_kw < 66
      insurance_month = 87.5
    elsif power_kw > 66 && power_kw < 99
      insurance_month = 98.8
    elsif power_kw > 99 && power_kw < 130
      insurance_month = 111.30
    elsif power_kw > 130 && power_kw < 210
      insurance_month = 134.00
    end

    # car tax
    if fuel_type == 'Diesel'
      car_tax_month = cubic_cap.to_f / 100 * diesel_tax_month
    elsif fuel_type == 'Benzin'
      car_tax_month = cubic_cap.to_f / 100 * benzin_tax_month
    elsif ['Elektro', 'Erdgas'].include?(fuel_type)
      car_tax_month = 0
    end

    car_tax_month += (emission - tolerance_emis) * emis_tax_month

    # depreciation
    depreciation_month = {
      's' => 12.0 / 100 * selling_price / 12,
      'm' => 14.0 / 100 * selling_price / 12,
      'l' => 16.0 / 100 * selling_price / 12,
      'xl' => 18.0 / 100 * selling_price / 12,
      'xxl' => 20.0 / 100 * selling_price / 12
    }

    # Create fee Hash and assign all subscription prices
    duration = 3
    fees = Hash.new
    while duration <= 12
      for package in ['s', 'm', 'l', 'xl', 'xxl'] do
        if  (package == 'xxl' && duration >= 6) || (package == 'xl' && duration >= 8) ||
            (package == 'l' && duration >= 10)
          maintenance_fee = maintenance
        end
        # payment provider share costs
        payment_share_cost = payment_share * (((ada_setup_cost + registration +
                             maintenance_fee + solvency_fee) / duration + warranty_month +
                             car_tax_month + insurance_month + gez_month + transaction_fee +
                             gen_inspection + depreciation_month[package] + loan_cost_month)) *
                             (1 + margin) * (1 + vat)
        fees["preis_#{duration}_#{package}"] = (((((ada_setup_cost + registration + maintenance_fee +
                                                solvency_fee) / duration + warranty_month + car_tax_month +
                                                insurance_month + gez_month + transaction_fee +
                                                gen_inspection + depreciation_month[package] + loan_cost_month +
                                                payment_share_cost)) * (1 + margin)) * (1 + vat)).round
      end
      duration += 1
    end

    # return fees Hash
    fees
  end

  def reselling_prices(selling_price_gross)
    # Tax
    vat = 16.0 / 100

    # registration cost
    registration = 100.0 / (1 + vat)

    # general inspection TUEV month
    gen_inspection_month = 100.0 / 12 / (1 + vat)

    # used car insurance
    warranty_month = 170.0 / 12 / (1 + vat)

    # net selling price
    selling_price = selling_price_gross / (1 + vat)

    # depreciation hash
    depreciation_month = {
      's' => 12.0 / 100 * selling_price / 12,
      'm' => 14.0 / 100 * selling_price / 12,
      'l' => 16.0 / 100 * selling_price / 12,
      'xl' => 18.0 / 100 * selling_price / 12,
      'xxl' => 20.0 / 100 * selling_price / 12
    }

    # determine subscription price and assign to reselling prices hash
    duration = 3
    reselling_prices = Hash.new
    while duration <= 12
      for package in ['s', 'm', 'l', 'xl', 'xxl'] do
        reselling_prices["#{duration}_#{package}"] =  (selling_price_gross - (registration +
                                                      (depreciation_month[package] + gen_inspection_month +
                                                      warranty_month) * duration) * (1 + vat)).round
      end
      duration += 1
    end

    # return reselling_prices hash
    reselling_prices
  end
end
