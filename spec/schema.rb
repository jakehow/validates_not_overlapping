ActiveRecord::Schema.define(:version => 0) do
  create_table :reservations, :force => true do |t|
    t.datetime :start
    t.datetime :finish
    t.integer :room_id
  end
  
  create_table :bookings, :force => true do |t|
    t.date :start
    t.date :finish
    t.integer :room_id
  end
end