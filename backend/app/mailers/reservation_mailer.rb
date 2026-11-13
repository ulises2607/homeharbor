class ReservationMailer < ApplicationMailer
  def notice
    @notification = params.fetch(:notification)
    @reservation = @notification.reservation
    @owner_view = @notification.audience == "owner"
    recipient = @owner_view ? @reservation.boat.owner : @reservation.user
    @title = @notification.event == "confirmed" ? "Reserva confirmada" : "Reserva cancelada"
    origin = ENV.fetch("FRONTEND_URL") { Rails.env.production? ? raise("FRONTEND_URL is required") : "http://127.0.0.1:5173" }.delete_suffix("/")
    @link = origin + (@owner_view ? "/my-boats/#{@reservation.boat_id}/reservations" : "/my-reservations/#{@reservation.id}")
    @deadline = @reservation.cancellation_deadline.strftime("%d/%m/%Y %H:%M")
    # Stable identifier aids deduplication; SMTP cannot guarantee exactly-once delivery.
    headers["Message-ID"] = "<reservation-notice-#{@notification.id}@homeharbor.invalid>"
    mail(to: recipient.email, subject: "#{@title} ##{@reservation.id} · Homeharbor")
  end
end
