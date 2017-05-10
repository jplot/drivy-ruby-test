require 'json'
require 'date'

data = JSON.parse(File.read(__dir__ + '/data.json'))
CARS = data['cars']
DISCOUNTS = { 1 => 10, 4 => 30, 10 => 50 }

def cost_compute(rental)
  car = CARS.find { |car| car['id'] == rental['car_id'] }
  period = (Date.parse(rental['end_date']) - Date.parse(rental['start_date'])).to_i + 1

  total_price_per_day = 1.upto(period).map do |day|
    discount = DISCOUNTS.map { |i, discount| day > i ? discount : 0 }.max
    car['price_per_day'] - (car['price_per_day'] * discount / 100)
  end.reduce(:+)

  total_price_per_km = car['price_per_km'] * rental['distance']
  deductible_reduction = rental['deductible_reduction'] ? 4 * period * 100 : 0
  total_price = total_price_per_day + total_price_per_km
  total_fee = total_price * 30 / 100
  insurance_fee = total_fee * 50 / 100
  assistance_fee = 1 * period * 100
  drivy_fee = total_fee - insurance_fee - assistance_fee + deductible_reduction

  {
    driver: total_price + deductible_reduction,
    owner: total_price - total_fee,
    insurance_fee: insurance_fee,
    assistance_fee: assistance_fee,
    drivy_fee: drivy_fee
  }
end

rental_modifications = data['rental_modifications'].map do |rental_modification|
  rental = data['rentals'].find { |rental| rental['id'] == rental_modification['rental_id'] }
  cost = cost_compute(rental)
  cost_modification = cost_compute(rental.merge(rental_modification))

  driver = cost_modification[:driver] - cost[:driver]
  owner = cost_modification[:owner] - cost[:owner]
  insurance_fee = cost_modification[:insurance_fee] - cost[:insurance_fee]
  assistance_fee = cost_modification[:assistance_fee] - cost[:assistance_fee]
  drivy_fee = cost_modification[:drivy_fee] - cost[:drivy_fee]

  {
    id: rental_modification['id'],
    rental_id: rental_modification['rental_id'],
    actions: [
      {
        who: 'driver',
        type: driver < 0 ? 'credit' : 'debit',
        amount: driver.abs
      },
      {
        who: 'owner',
        type: owner < 0 ? 'debit' : 'credit',
        amount: owner.abs
      },
      {
        who: 'insurance',
        type: insurance_fee < 0 ? 'debit' : 'credit',
        amount: insurance_fee.abs
      },
      {
        who: 'assistance',
        type: assistance_fee < 0 ? 'debit' : 'credit',
        amount: assistance_fee.abs
      },
      {
        who: 'drivy',
        type: drivy_fee < 0 ? 'debit' : 'credit',
        amount: drivy_fee.abs
      }
    ]
  }
end

File.write(__dir__ + '/output.json', JSON.pretty_generate(rental_modifications: rental_modifications))
