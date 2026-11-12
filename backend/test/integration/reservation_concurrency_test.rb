require "test_helper"

class ReservationConcurrencyTest < ActiveSupport::TestCase
  self.use_transactional_tests = false
  setup do
    @users = 3.times.map do |index|
      User.new(name: "Concurrency #{index}", email: "booking-#{SecureRandom.hex(8)}@example.test",
        password: "Concurrent-booking-2026!", password_confirmation: "Concurrent-booking-2026!").tap do |user|
        user.skip_confirmation!
        user.save!
      end
    end
    @boats = 2.times.map { |index| @users.first.boats.create!(name: "Concurrent #{index}", description: "Test", port: "Tigre", capacity: 6, daily_rate_cents: 10000) }
    first = Date.current + 10
    @attributes = { boat_id: @boats.first.id, starts_on: first.iso8601, ends_on: (first + 2).iso8601, passengers: 4, expected_total_cents: 20000, expected_currency: "USD" }
  end
  teardown do
    Reservation.where(boat_id: @boats.map(&:id)).delete_all
    @boats.each { |boat| boat.reload.destroy! }
    @users.each { |user| user.reload.destroy! }
  end

  def concurrently(&block)
    ready, start = Queue.new, Queue.new
    threads = 2.times.map do |index|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          ready << true
          start.pop
          block.call(index)
        end
      end
    end
    2.times { ready.pop }
    2.times { start << true }
    threads.map(&:value)
  ensure
    threads&.each(&:join)
  end

  test "different customers racing for the same dates produce one confirmation" do
    results = concurrently do |index|
      CreateReservation.call(user: User.find(@users[index + 1].id), attributes: @attributes, idempotency_key: SecureRandom.uuid)
      :confirmed
    rescue ReservationError => error
      error.code
    end
    assert_equal [:availability_conflict, :confirmed], results.sort
    assert_equal 1, @boats.first.reservations.confirmed.count
  end

  test "concurrent retries with the same key return exactly one reservation" do
    key = SecureRandom.uuid
    results = concurrently do
      CreateReservation.call(user: User.find(@users[1].id), attributes: @attributes, idempotency_key: key)
    end
    assert_equal 1, results.map { |record, _| record.id }.uniq.size
    assert_equal [false, true], results.map(&:last).sort_by(&:to_s)
    assert_equal 1, @boats.first.reservations.count
  end

  test "same key reused concurrently across boats conflicts instead of creating twice" do
    key = SecureRandom.uuid
    results = concurrently do |index|
      CreateReservation.call(user: User.find(@users[1].id), attributes: @attributes.merge(boat_id: @boats[index].id), idempotency_key: key)
      :created
    rescue ReservationError => error
      error.code
    end
    assert_equal [:created, :idempotency_conflict], results.sort
    assert_equal 1, Reservation.where(boat_id: @boats.map(&:id)).count
  end

  test "capacity changes and bookings share a lock and cannot violate passenger capacity" do
    results = concurrently do |index|
      if index.zero?
        boat = Boat.find(@boats.first.id)
        boat.with_lock { boat.update!(capacity: 3) }
      else
        CreateReservation.call(user: User.find(@users[1].id), attributes: @attributes, idempotency_key: SecureRandom.uuid)
      end
      :saved
    rescue ActiveModel::ValidationError, ActiveRecord::RecordInvalid
      :rejected
    end
    assert_equal [:rejected, :saved], results.sort
    boat = @boats.first.reload
    assert_not boat.reservations.confirmed.where("passengers > ?", boat.capacity).exists?
  end
end
