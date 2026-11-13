require "test_helper"

class ReservationNotificationsTest < ActiveSupport::TestCase
  class FailingDelivery
    def initialize(*) = nil
    def deliver!(_mail) = raise(IOError, "private SMTP response")
  end
  ActionMailer::Base.add_delivery_method :failing_test, FailingDelivery
  setup do
    travel_to Time.utc(2026, 12, 1, 15)
    @owner, @guest = %w[owner guest].map do |name|
      User.new(name: name, email: "#{name}@notifications.test", password: "Notification-test-2026!",
        password_confirmation: "Notification-test-2026!").tap { |user| user.skip_confirmation!; user.save! }
    end
    @boat = @owner.boats.create!(name: "Brisa <script>", description: "Demo", port: "Tigre", capacity: 6, daily_rate_cents: 12000)
    @attributes = { boat_id: @boat.id, starts_on: "2026-12-10", ends_on: "2026-12-12",
      passengers: 4, expected_total_cents: 24000, expected_currency: "USD" }
    @key = SecureRandom.uuid
    ActionMailer::Base.deliveries.clear
  end
  teardown { travel_back; ActionMailer::Base.deliveries.clear }

  def book
    CreateReservation.call(user: @guest, attributes: @attributes, idempotency_key: @key).first
  end

  def with_failed_delivery
    previous = ReservationMailer.delivery_method
    ReservationMailer.delivery_method = :failing_test
    yield
  ensure
    ReservationMailer.delivery_method = previous
  end

  test "booking and cancellation persist exactly one notice per audience and event" do
    reservation = book
    assert_equal 2, ReservationNotification.count
    assert_empty ActionMailer::Base.deliveries
    book
    assert_equal 2, ReservationNotification.count
    2.times { CancelReservation.call(reservation) }
    assert_equal 4, ReservationNotification.count
    assert_equal %w[customer owner], ReservationNotification.where(event: "cancelled").pluck(:audience).sort
  end

  test "failed transaction does not leave either booking or notice behind" do
    Reservation.transaction(requires_new: true) { book; raise ActiveRecord::Rollback }
    assert_equal 0, Reservation.count
    assert_equal 0, ReservationNotification.count
  end

  test "delivery sends separate HTML and plain text messages with correct private links" do
    reservation = book
    assert_equal 2, DeliverReservationNotifications.call
    assert_equal 2, ActionMailer::Base.deliveries.size
    customer = ActionMailer::Base.deliveries.find { |mail| mail.to == [@guest.email] }
    owner = ActionMailer::Base.deliveries.find { |mail| mail.to == [@owner.email] }
    assert_includes customer.text_part.body.decoded, "/my-reservations/#{reservation.id}"
    assert_includes owner.text_part.body.decoded, "/my-boats/#{@boat.id}/reservations"
    assert_includes customer.html_part.body.decoded, "Brisa &lt;script&gt;"
    assert_includes customer.text_part.body.decoded, "240.00 USD"
    assert_includes customer.text_part.body.decoded, "09/12/2026 00:00 UTC−3"
    assert_nil customer.cc
    assert_nil customer.bcc
    assert_equal 0, DeliverReservationNotifications.call
    assert_equal 2, ActionMailer::Base.deliveries.size
  end

  test "transport failure schedules retry and cannot undo the confirmed reservation" do
    reservation = book
    with_failed_delivery { assert_equal 2, DeliverReservationNotifications.call }
    assert_equal "confirmed", reservation.reload.status
    assert_equal 2, ReservationNotification.where(attempts: 1, last_error: "IOError", delivered_at: nil).count
    assert_equal 0, DeliverReservationNotifications.call
    travel 2.minutes
    assert_equal 2, DeliverReservationNotifications.call
    assert_equal 2, ReservationNotification.where.not(delivered_at: nil).count
  end

  test "retry exhaustion is visible without exposing provider error messages" do
    book
    with_failed_delivery do
      5.times { DeliverReservationNotifications.call; travel 1.hour }
    end
    assert_equal 2, ReservationNotification.where.not(failed_at: nil).count
    assert_equal 0, ReservationNotification.pending.count
    assert_equal ["IOError"], ReservationNotification.distinct.pluck(:last_error)
    assert_equal [5], ReservationNotification.distinct.pluck(:attempts)
  end

  test "late confirmation notice makes a subsequent cancellation clear" do
    reservation = book
    CancelReservation.call(reservation)
    DeliverReservationNotifications.call
    assert_equal 4, ActionMailer::Base.deliveries.size
    confirmation = ActionMailer::Base.deliveries.find { |mail| mail.subject.start_with?("Reserva confirmada") }
    assert_includes confirmation.text_part.body.decoded, "cancelada posteriormente"
    cancellation = ActionMailer::Base.deliveries.find { |mail| mail.subject.start_with?("Reserva cancelada") }
    assert_includes cancellation.text_part.body.decoded, "Se liberaron las fechas"
  end

  test "database rejects duplicate event and recipient" do
    book
    row = ReservationNotification.first.attributes.except("id")
    assert_raises(ActiveRecord::RecordNotUnique) do
      ReservationNotification.transaction(requires_new: true) { ReservationNotification.insert_all!([row]) }
    end
  end
end
