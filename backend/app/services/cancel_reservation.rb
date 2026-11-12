class CancelReservation
  def self.call(reservation)
    reservation.boat.with_lock do
      reservation.with_lock do
        unless reservation.status == "cancelled"
          unless reservation.cancellable?
            raise ReservationError.new(:cancellation_closed, "El plazo para cancelar terminó: se requieren al menos 24 horas antes del inicio.")
          end
          reservation.update!(status: "cancelled", cancelled_at: Time.current)
        end
      end
    end
    reservation
  end
end
