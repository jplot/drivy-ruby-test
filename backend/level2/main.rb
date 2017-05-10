require 'json'
require 'date'

discounts = { 1 => 10, 4 => 30, 10 => 50 }
data = JSON.parse(File.read(__dir__ + '/data.json'))
cars = data['cars']
rentals = data['rentals'].map do |rental|
  car = cars.find { |car| car['id'] == rental['car_id'] }
  period = (Date.parse(rental['end_date']) - Date.parse(rental['start_date'])).to_i + 1

  total_price_per_day = 1.upto(period).map do |day|
    discount = discounts.map { |i, discount| day > i ? discount : 0 }.max
    car['price_per_day'] - (car['price_per_day'] * discount / 100)
  end.reduce(:+)

  total_price_per_km = car['price_per_km'] * rental['distance']

  { id: rental['id'], price: total_price_per_day + total_price_per_km }
end

File.write(__dir__ + '/output.json', JSON.pretty_generate(rentals: rentals))
