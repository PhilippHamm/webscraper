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
    cars = scraper(@car, car_params[:url_path])
  end

  def destroy
  end

  # This is just for checking the form style of the dealer landing page, not relevant for scraper
  def form
  end

  private
  def car_params
    params.require(:car_dealer).permit(:url_path)
  end

  def pricing(selling_price,power,cubic_cap,fuel_type)
    # non-recurring costs
    registration = 100.0
    warranty_month = 232.0 / 12
    # only occurs every 10000 km
    maintenance = 100.0
    maintenance_fee = 0
    # recurring costs
    loan_interest_year = 6.0 / 100
    loan_cost_month = loan_interest_year * selling_price / 12
    margin = 30.0 / 100
    gez_month = 5.38
    # payment provider
    transaction_fee = 0.36
    solvency_fee = 0.45
    payment_share = 3.0 / 1000
    # setup_fee = 199.0
    # vat = 16.0 / 100
    # insurance
    power_kw = power / 1.36
    if power_kw < 66
      insurance_month = 66.0
    elsif power_kw > 66 && power_kw < 99
      insurance_month = 95.0
    elsif power_kw > 99 && power_kw < 130
      insurance_month = 130.0
    elsif power_kw > 130 && power_kw < 210
      insurance_month = 123.0
    end
    # car tax
    if fuel_type == 'Diesel'
      car_tax_month = cubic_cap.to_f / 100 * 9.5 / 12
    elsif fuel_type == 'Benzin'
      car_tax_month = cubic_cap.to_f / 100 * 2 / 12
    elsif fuel_type == 'Elektro' || fuel_type == 'Erdgas'
      car_tax_month = 0
    end
    # depreciation
    depreciation_month = {
      's' => 12.0 / 100 * selling_price / 12,
      'm' => 14.0 / 100 * selling_price / 12,
      'l' => 16.0 / 100 * selling_price / 12,
      'xl' => 18.0 / 100 * selling_price / 12,
      'xxl' => 20.0 / 100 * selling_price / 12
    }

    # subscription price
    i = 3
    fees = Hash.new
    while i <= 12
      for a in ['s', 'm', 'l', 'xl', 'xxl'] do
        if  a == 'xxl' && i >= 6 || a == 'xl' && i >= 8 || a == 'l' && i >= 10
          maintenance_fee = maintenance
        end
        fees["preis_#{i}_#{a}"] = ((((registration + maintenance_fee +
                                  solvency_fee) / i + warranty_month + car_tax_month +
                                  insurance_month + gez_month + transaction_fee +
                                  depreciation_month[a] + loan_cost_month)) *
                                  (1 + margin) * (1 + payment_share)).round
      end
      i += 1
    end
    fees
  end

  def scraper(url_path)
    # open csv file
    csv_options = { col_sep: ',' }
    filepath    = Rails.root.join('lib', 'data', 'koch-marzahn.csv')
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
    #Setting capybara driver
    Capybara.default_driver = :selenium_chrome # :selenium_chrome and :selenium_chrome_headless are also registered
    Capybara.run_server = false
    Capybara.app_host = 'https://www.mobile.de'
    Capybara.default_max_wait_time = 3
    Capybara.raise_server_errors = false
    begin
      visit('https://home.mobile.de/AH-SCHACHTSCHNEIDER#ses')
    rescue Net::ReadTimeout
    end
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
    p = 0
    q = all('#ses > div.ses > ul > li').map { |a| a['id'] }
    q.each do |id|
      # visit car view page
      visit("https://home.mobile.de/AH-SCHACHTSCHNEIDER#des_#{id}")
      sleep(1)
      # create new hash car
      car = Hash.new

      begin

        attributes = find('#des > div.des > div > div.vehicleMainInfo.right > div.vehicleAttributes > div.left > span.attributes').text
        car["Kilometerstand"] = attributes.match(/(\d*[.]\d{3}|\d*) km/)[0]
        car["Leistung"] = attributes.match(/\d*\skW\s.\d*\sPS./)[0]
        car["Kraftstoffart"] = attributes.match(/(Benzin|Diesel|Elektro|Erdgas)/)[0]
        car["Preis"] = find('#des > div.des > div > div.vehicleMainInfo.right > div.vehiclePrice > strong').text.gsub(' Brutto', '')
        begin
          car["Erstzulassung"] = attributes.match(/\d{2}.\d{4}/)[0]
        rescue NoMethodError
        end

        # Test if the car fulfils requirements
        km_stand = car["Kilometerstand"].gsub(/[^\d]/,'').to_i
        power = car["Leistung"].match(/^\d*/)[0].to_i
        price = car["Preis"].gsub(/[^\d]/,'').to_i
        if km_stand < 60000 && km_stand > 10000 && price < 30000 && power < 210 && car["Kraftstoffart"].match?(/(Diesel|Benzin)/)
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
          # image position holder csv
          j = 1
          20.times do
            if car["Bild_#{j}"]
              car["Bild_index_#{j}"] = j
              j += 1
            end
          end
          find('#galleryLarge > div > div.imageView.flexslider.mainImage.modalBox > div > ul > li.slide.Large.flex-active-slide > div > img', visible: false).click

          # assign data to hash

          car["Kategorie"] = all('#des > div.des > div > div.vehicleMainInfo.right > div.vehicleAttributes > div.left > strong')[0].text
          car["Titel"] = find('#des > div.des > h3').text
          car["Herkunft"] = find('#des > div.des > div > div.vehicleMainInfo.right > div.vehicleAttributes > div.left > span.countryVersion').text
          begin
            car["Fahrzeugzustand"] = find('#des > div.des > div > div.vehicleMainInfo.right > div.vehicleAttributes > div.left > span.damaged').text
          rescue Capybara::ElementNotFound
          end

          car["Getriebe"] = attributes.match(/(Automatik|Schaltgetriebe)/)[0]
          car["Verbrauch"] = find('#des > div.des > div > div.vehicleTechDetails.row-fluid > dl.fuelConsumption.span10 > dd:nth-child(2)').text.gsub(')',')<br>')
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
          car["Weitere Eigenschaften"] = features.join(", ")
          # assign link to hash
          car["Link"] = "https://home.mobile.de/AH-SCHACHTSCHNEIDER#des_#{id}"

          # Assign data for import sheet shopify
          car['Vendor'] = car['Titel'].match(/^[A-Za-z-]*/)[0]
          car['Title'] = car['Titel'].gsub(/[+&\/.;,()'_]/, ' ')
          car['Handle'] = "#{car['Title'].gsub(/\s/,'-')}"
          car['Dealer'] = find('#container > footer > div > div > div:nth-child(3) > address > strong').text
          car['Pickup_location'] = find('#container > footer > div > div > div:nth-child(3) > address > div.span12.addressData').text
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
          # Create tags
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
            leistung_tag = ['Leistung_Alle']
          end
          getriebe_tag = "Schaltung_#{car['Getriebe']}"
          if car['Farbe'].nil?
            farbe_tag = 'Farbe_Alle'
          else
            farbe_tag = "Farbe_#{car['Farbe'].match(/^[A-Za-zäöüß]*/)[0]}"
          end
          kraftstoff_tag = "Kraftstoff_#{car['Kraftstoffart']}"
          zustand_tag = "Zustand_Gebraucht"

          # pricing arithmetic
          abo_preise = pricing( car['Preis'].gsub(/[^\d]/,'').to_i,leistung.to_i,
                                car['Hubraum'].gsub(/[^\d]/,'').to_i,
                                car["Kraftstoffart"])
          car.merge!(abo_preise)
          # pricing arithmetic

          if car['preis_3_s'] < 200
            preis_tag = "Preis_Günstig (bis 200 €)"
          elsif car['preis_3_s'] > 200 && abo_preise['preis_3_s'] < 400
            preis_tag = "Preis_Mittel (200 bis 400 €)"
          elsif car['preis_3_s'] > 400
            preis_tag = "Preis_Premium (ab 400 €)"
          end

          # concat all tags
          car['Tags'] = "#{marke_tag}, #{typ_tag}, #{alter_tag.join(',')}, #{km_stand_tag.join(',')}, #{leistung_tag.join(',')}, #{getriebe_tag}, #{farbe_tag}, #{kraftstoff_tag}, #{zustand_tag}, #{preis_tag}"

          # cars.push(car)
          # puts "total quantity #{cars.length}"
        # j += 1
        # break if j > 5

      # # find all car characteristics
      # all_cars = Hash.new
      # cars.each do |car|
      #   all_cars.merge!(car)
      # end

      # # build array with all hash keys
      # header_array = all_cars.keys
      # # header_string = header_array.join(',')

          CSV.open(filepath, 'a', csv_options) do |csv|
          # car.each do |car|
            csv << [
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
              car['Bild_index_21'],
              'nil'
            ]
            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '3 Monate', nil, "1000 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_3_m'], nil,
                    'FALSCH', 'WAHR']

            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '3 Monate', nil, "1500 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_3_l'], nil,
                    'FALSCH', 'WAHR']

            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '3 Monate', nil, "2000 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_3_xl'], nil,
                    'FALSCH', 'WAHR']

            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '3 Monate', nil, "2500 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_3_xxl'], nil,
                    'FALSCH', 'WAHR']

            # 4 Monate

            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '4 Monate', nil, "500 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_4_s'], nil,
                    'FALSCH', 'WAHR']
            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '4 Monate', nil, "1000 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_4_m'], nil,
                    'FALSCH', 'WAHR']
            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '4 Monate', nil, "1500 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_4_l'], nil,
                    'FALSCH', 'WAHR']
            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '4 Monate', nil, "2000 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_4_xl'], nil,
                    'FALSCH', 'WAHR']
            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '4 Monate', nil, "2500 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_4_xxl'], nil,
                    'FALSCH', 'WAHR']

            # 5 Monate
            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '5 Monate', nil, "500 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_5_s'], nil,
                    'FALSCH', 'WAHR']
            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '5 Monate', nil, "1000 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_5_m'], nil,
                    'FALSCH', 'WAHR']
            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '5 Monate', nil, "1500 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_5_l'], nil,
                    'FALSCH', 'WAHR']
            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '5 Monate', nil, "2000 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_5_xl'], nil,
                    'FALSCH', 'WAHR']
            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '5 Monate', nil, "2500 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_5_xxl'], nil,
                    'FALSCH', 'WAHR']
            # 6 Monate
            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '6 Monate', nil, "500 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_6_s'], nil,
                    'FALSCH', 'WAHR']
            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '6 Monate', nil, "1000 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_6_m'], nil,
                    'FALSCH', 'WAHR']
            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '6 Monate', nil, "1500 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_6_l'], nil,
                    'FALSCH', 'WAHR']
            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '6 Monate', nil, "2000 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_6_xl'], nil,
                    'FALSCH', 'WAHR']
            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '6 Monate', nil, "2500 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_6_xxl'], nil,
                    'FALSCH', 'WAHR']
            # 7 Monate
            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '7 Monate', nil, "500 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_7_s'], nil,
                    'FALSCH', 'WAHR']
            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '7 Monate', nil, "1000 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_7_m'], nil,
                    'FALSCH', 'WAHR']
            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '7 Monate', nil, "1500 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_7_l'], nil,
                    'FALSCH', 'WAHR']
            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '7 Monate', nil, "2000 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_7_xl'], nil,
                    'FALSCH', 'WAHR']
            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '7 Monate', nil, "2500 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_7_xxl'], nil,
                    'FALSCH', 'WAHR']

            # 8 Monate
            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '8 Monate', nil, "500 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_8_s'], nil,
                    'FALSCH', 'WAHR']
            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '8 Monate', nil, "1000 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_8_m'], nil,
                    'FALSCH', 'WAHR']
            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '8 Monate', nil, "1500 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_8_l'], nil,
                    'FALSCH', 'WAHR']
            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '8 Monate', nil, "2000 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_8_xl'], nil,
                    'FALSCH', 'WAHR']
            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '8 Monate', nil, "2500 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_8_xxl'], nil,
                    'FALSCH', 'WAHR']
            # 9 Monate
            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '9 Monate', nil, "500 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_9_s'], nil,
                    'FALSCH', 'WAHR']
            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '9 Monate', nil, "1000 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_9_m'], nil,
                    'FALSCH', 'WAHR']
            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '9 Monate', nil, "1500 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_9_l'], nil,
                    'FALSCH', 'WAHR']
            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '9 Monate', nil, "2000 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_9_xl'], nil,
                    'FALSCH', 'WAHR']
            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '9 Monate', nil, "2500 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_9_xxl'], nil,
                    'FALSCH', 'WAHR']

            # 10 Monate
            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '10 Monate', nil, "500 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_10_s'], nil,
                    'FALSCH', 'WAHR']
            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '10 Monate', nil, "1000 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_10_m'], nil,
                    'FALSCH', 'WAHR']
            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '10 Monate', nil, "1500 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_10_l'], nil,
                    'FALSCH', 'WAHR']
            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '10 Monate', nil, "2000 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_10_xl'], nil,
                    'FALSCH', 'WAHR']
            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '10 Monate', nil, "2500 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_10_xxl'], nil,
                    'FALSCH', 'WAHR']

            # 11 Monate
            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '11 Monate', nil, "500 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_11_s'], nil,
                    'FALSCH', 'WAHR']
            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '11 Monate', nil, "1000 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_11_m'], nil,
                    'FALSCH', 'WAHR']
            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '11 Monate', nil, "1500 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_11_l'], nil,
                    'FALSCH', 'WAHR']
            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '11 Monate', nil, "2000 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_11_xl'], nil,
                    'FALSCH', 'WAHR']
            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '11 Monate', nil, "2500 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_11_xxl'], nil,
                    'FALSCH', 'WAHR']

            # 12 Monate
            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '12 Monate', nil, "500 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_12_s'], nil,
                    'FALSCH', 'WAHR']
            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '12 Monate', nil, "1000 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_12_m'], nil,
                    'FALSCH', 'WAHR']
            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '12 Monate', nil, "1500 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_12_l'], nil,
                    'FALSCH', 'WAHR']
            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '12 Monate', nil, "2000 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_12_xl'], nil,
                    'FALSCH', 'WAHR']
            csv << [car['Handle'], nil, nil, nil, nil, nil, nil, nil, '12 Monate', nil, "2500 km",
                    nil, nil, 'ADA', '0', nil, '0', 'deny', 'manual', car['preis_12_xxl'], nil,
                    'FALSCH', 'WAHR']
          # end
          end
          # p += 1
          # break if p > 30
        end
      rescue Capybara::ElementNotFound
      rescue TypeError
      rescue Selenium::WebDriver::Error::StaleElementReferenceError
      rescue NoMethodError
      end
    end
    # # open csv file
    # csv_options = { col_sep: ',' }
    # filepath    = Rails.root.join('lib', 'data', 'schachtschneider.csv')
    # # write headline csv
    # CSV.open(filepath, 'wb', csv_options) do |csv|
    #   csv << [
    #       header_array[0],
    #       header_array[1],
    #       header_array[2],
    #       header_array[3],
    #       header_array[4],
    #       header_array[5],
    #       header_array[6],
    #       header_array[7],
    #       header_array[8],
    #       header_array[9],
    #       header_array[10],
    #       header_array[11],
    #       header_array[12],
    #       header_array[13],
    #       header_array[14],
    #       header_array[15],
    #       header_array[16],
    #       header_array[17],
    #       header_array[18],
    #       header_array[19],
    #       header_array[20],
    #       header_array[21],
    #       header_array[22],
    #       header_array[23],
    #       header_array[24],
    #       header_array[25],
    #       header_array[26],
    #       header_array[27],
    #       header_array[28],
    #       header_array[29],
    #       header_array[30],
    #       header_array[31],
    #       header_array[32],
    #       header_array[33],
    #       header_array[34],
    #       header_array[35],
    #       header_array[36],
    #       header_array[37],
    #       header_array[38],
    #       header_array[39],
    #       header_array[40],
    #       header_array[41],
    #       header_array[42],
    #       header_array[43],
    #       header_array[44],
    #       header_array[45],
    #       header_array[46]
    #     ]
    # end
    # CSV.open(filepath, 'a', csv_options) do |csv|
    #   cars.each do |car|
    #     csv << [
    #       car[header_array[0]],
    #       car[header_array[1]],
    #       car[header_array[2]],
    #       car[header_array[3]],
    #       car[header_array[4]],
    #       car[header_array[5]],
    #       car[header_array[6]],
    #       car[header_array[7]],
    #       car[header_array[8]],
    #       car[header_array[9]],
    #       car[header_array[10]],
    #       car[header_array[11]],
    #       car[header_array[12]],
    #       car[header_array[13]],
    #       car[header_array[14]],
    #       car[header_array[15]],
    #       car[header_array[16]],
    #       car[header_array[17]],
    #       car[header_array[18]],
    #       car[header_array[19]],
    #       car[header_array[20]],
    #       car[header_array[21]],
    #       car[header_array[22]],
    #       car[header_array[23]],
    #       car[header_array[24]],
    #       car[header_array[25]],
    #       car[header_array[26]],
    #       car[header_array[27]],
    #       car[header_array[28]],
    #       car[header_array[29]],
    #       car[header_array[30]],
    #       car[header_array[31]],
    #       car[header_array[32]],
    #       car[header_array[33]],
    #       car[header_array[34]],
    #       car[header_array[35]],
    #       car[header_array[36]],
    #       car[header_array[37]],
    #       car[header_array[38]],
    #       car[header_array[39]],
    #       car[header_array[40]],
    #       car[header_array[41]],
    #       car[header_array[42]],
    #       car[header_array[43]],
    #       car[header_array[44]],
    #       car[header_array[45]],
    #       car[header_array[46]]
    #     ]
    #   end
    # end
  end
end
