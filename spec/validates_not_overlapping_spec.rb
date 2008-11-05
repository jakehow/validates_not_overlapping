require File.dirname(__FILE__) + '/spec_helper'

describe 'Reservation (no equal endpoints)' do
  class Reservation < ActiveRecord::Base
    validates_not_overlapping :start, :finish
  end
  
  before(:all) do
    @start = Time.now + 1.hour
    @finish = Time.now + 3.hours
  end
  
  before(:each) do
    Reservation.create(:start => @start, :finish => @finish)
  end
  
  it "is valid if it does not overlap at all" do
    new_reservation = Reservation.new(:start => @finish + 1.hour, :finish => @finish + 3.hours)
    new_reservation.should be_valid
  end
  
  it "is invalid if record exists with: start before current's finish and after current's start" do
    new_reservation = Reservation.new(:start => @start + 1.hour, :finish => @finish)
    new_reservation.should_not be_valid
  end
  
  it "is invalid if record exists with: start on current's start" do
    new_reservation = Reservation.new(:start => @start, :finish => @finish + 1.hour)
    new_reservation.should_not be_valid
  end
  
  it "is invalid if record exists with: finish after current's start and before current's finish" do
    new_reservation = Reservation.new(:start => @start + 30.minutes, :finish => @finish + 1.hour)
    new_reservation.should_not be_valid
  end
  
  it "is invalid if record exists with: finish after current's start and on current's finish" do
    new_reservation = Reservation.new(:start => @start + 30.minutes, :finish => @finish)
    new_reservation.should_not be_valid
  end
  
  it "is invalid if record exists with: start before current's start and finish after current's finish" do
    new_reservation = Reservation.new(:start => @start + 30.minutes, :finish => @finish + 30.minutes)
    new_reservation.should_not be_valid
  end
  
  it "is invalid if record exists with: start before current's start and finish on current's finish" do
    new_reservation = Reservation.new(:start => @start + 30.minutes, :finish => @finish)
    new_reservation.should_not be_valid
  end
  
  it "is invalid if record exists with: start on current's start and finish after current's finish" do
    new_reservation = Reservation.new(:start => @start, :finish => @finish - 30.minutes)
    new_reservation.should_not be_valid
  end
  
  it "is invalid if record exists with: start on current's start and finish on current's finish" do
    new_reservation = Reservation.new(:start => @start, :finish => @finish)
    new_reservation.should_not be_valid
  end
  
  it "is invalid if record exists with: start is after current's start and finish is before current's finish" do
    new_reservation = Reservation.new(:start => @start - 30.minutes, :finish => @finish + 30.minutes)
    new_reservation.should_not be_valid
  end
  
  it "is invalid if record exists with: finish is unset and current's finish is unset" do
    Reservation.delete_all
    Reservation.create(:start => @start)
    new_reservation = Reservation.new(:start => @start - 30.minutes)
    new_reservation.should_not be_valid
  end
  
  it "is invalid if record exists with: start is before current's finish and finish is unset" do
    Reservation.delete_all
    Reservation.create(:start => @start)
    new_reservation = Reservation.new(:start => @start - 5.hours, :finish => @start + 30.minutes)
    new_reservation.should_not be_valid
  end
  
  it "is invalid if record exists with: start is on current's finish" do
    new_reservation = Reservation.new(:start => @start.last_month, :finish => @start)
    new_reservation.should_not be_valid
  end
  
  it "is invalid if record exists with: finish is on current's start" do
    new_reservation = Reservation.new(:start => @finish, :finish => @finish.next_week)
    new_reservation.should_not be_valid
  end
  
  after(:each) do
    Reservation.delete_all
  end
end

describe 'Booking (allows equal endpoints)' do
  class Booking < ActiveRecord::Base
    validates_presence_of :start, :finish
    validates_not_overlapping :start, :finish, :allow_equal_endpoints => true
  end
  
  before(:all) do
    @start = Date.today
    @finish = Date.today.tomorrow.tomorrow.tomorrow
    Booking.create(:start => @start, :finish => @finish)
  end
  
  it 'should have one booking' do
    Booking.count.should eql(1)
  end
  
  it "is valid if it does not overlap at all" do
    new_booking = Booking.new(:start => @finish.next_week, :finish => @finish.next_month)
    new_booking.should be_valid
  end
  
  it "is valid if it old one's start is equal to new one's finish" do
    new_booking = Booking.new(:start => @start.last_month, :finish => @start)
    new_booking.should be_valid
  end
  
  it "is valid if it old one's finish is equal to new one's start" do
    new_booking = Booking.new(:start => @finish, :finish => @finish.next_week)
    new_booking.should be_valid
  end
  
  it "should not be valid when overlapping front end of existing record" do
    new_booking = Booking.new(:start => @start.yesterday, :finish => @start.tomorrow)
    new_booking.should_not be_valid
  end
  
  it "should not be valid when overlapping back end of existing record" do
    new_booking = Booking.new(:start => @start.tomorrow, :finish => @finish.tomorrow)
    new_booking.should_not be_valid
  end
  
  it "should not be valid when it fits inside of existing record" do
    new_booking = Booking.new(:start => @start.tomorrow, :finish => @finish.yesterday)
    new_booking.should_not be_valid
  end
  
  it "should not be valid when existing record fits inside of new record" do
    new_booking = Booking.new(:start => @start.yesterday, :finish => @finish.tomorrow)
    new_booking.should_not be_valid
  end
  
  it "should not be valid when identical existing record" do
    new_booking = Booking.new(:start => @start, :finish => @finish)
    new_booking.should_not be_valid
  end
  
  after(:all) do
    Booking.delete_all
  end
end

describe 'Booking with scope string' do
  class BookingScopedString < ActiveRecord::Base
    set_table_name 'bookings'
    validates_presence_of :start, :finish
    validates_not_overlapping :start, :finish, :allow_equal_endpoints => true, :scope => '`bookings`.room_id = #{room_id}'
  end
  
  before(:all) do
    @start = Date.today
    @finish = Date.today.tomorrow.tomorrow.tomorrow
    BookingScopedString.create(:start => @start, :finish => @finish, :room_id => 1)
  end
  
  it "overlapping should still be valid if they are outside each other's scope" do
    new_booking = BookingScopedString.new(:start=>@start, :finish=>@start.tomorrow, :room_id =>2)
    new_booking.should be_valid
  end
  
  it "overlapping should not be valid if they are inside each other's scope" do
    new_booking = BookingScopedString.new(:start=>@start, :finish=>@start.tomorrow, :room_id =>1)
    new_booking.should_not be_valid
  end
  
  it "is invalid if record exists with: start on current's start and finish unset" do
    BookingScopedString.delete_all
    BookingScopedString.create(:start => @start, :room_id => 1)
    new_booking = BookingScopedString.new(:start => @start, :room_id => 1)
    new_booking.should_not be_valid
  end
  
  after(:all) do
    BookingScopedString.delete_all
  end
end

describe 'Booking with scope symbol' do
  class BookingScopedSymbol < ActiveRecord::Base
    set_table_name 'bookings'
    validates_presence_of :start, :finish
    validates_not_overlapping :start, :finish, :allow_equal_endpoints => true, :scope => :room_id
  end
  
  before(:all) do
    @start = Date.today
    @finish = Date.today.tomorrow.tomorrow.tomorrow
    BookingScopedSymbol.create(:start => @start, :finish => @finish, :room_id => 1)
  end
  
  it "should still be valid if overlapping but they are outside each other's scope" do
    new_booking = BookingScopedSymbol.new(:start=>@start, :finish=>@start.tomorrow, :room_id =>2)
    new_booking.should be_valid
  end
  
  it "should not be valid if overlapping inside each other's scope" do
    new_booking = BookingScopedSymbol.new(:start=>@start, :finish=>@start.tomorrow, :room_id =>1)
    new_booking.should_not be_valid
  end
  
  after(:all) do
    BookingScopedSymbol.delete_all
  end
end