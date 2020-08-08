class CarDealer < ApplicationRecord
  validates :url_path, presence: true
end
