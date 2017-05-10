require 'json'
require 'date'

data = JSON.parse(File.read(__dir__ + '/data.json'))
cars = data['cars']
rentals = data['rentals'].map do |rental|
  car = cars.find { |car| car['id'] == rental['car_id'] }
  period = (Date.parse(rental['end_date']) - Date.parse(rental['start_date'])).to_i + 1
  price = (car['price_per_day'] * period) + (car['price_per_km'] * rental['distance'])

  { id: rental['id'], price: price }
end

File.write(__dir__ + '/output.json', JSON.pretty_generate(rentals: rentals))
