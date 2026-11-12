class CreateReservation
  def self.call(user:, attributes:, idempotency_key:)
    key = idempotency_key.to_s.downcase
    unless key.match?(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/)
      raise ReservationError.new(:invalid_idempotency_key, "Enviá una clave UUID para esta operación.", status: :bad_request)
    end
    request = ReservationRequest.new(attributes, booking: true)
    request.validate!
    result = nil
    # User first, boat second: same-key requests serialize even across different boats.
    user.with_lock do
      previous = user.reservations.find_by(idempotency_key: key)
      if previous
        unless previous.request_fingerprint == request.fingerprint
          raise ReservationError.new(:idempotency_conflict, "Esa operación ya se usó con otros datos.")
        end
        result = [previous, false]
      else
        boat = Boat.find(request.boat_id)
        boat.with_lock do
          raise ActiveRecord::RecordNotFound unless boat.active?
          if boat.owner_id == user.id
            raise ReservationError.new(:own_boat, "No podés reservar tu propio bote.", status: :forbidden)
          end
          request.validate_for_boat!(boat)
          quote = request.quote(boat)
          unless request.expected_total_cents == quote[:total_cents] && request.expected_currency == quote[:currency]
            raise ReservationError.new(:price_changed, "La tarifa cambió. Consultá el precio nuevamente antes de confirmar.")
          end
          if boat.reservations.confirmed.overlapping(request.starts_on, request.ends_on).exists?
            raise ReservationError.new(:availability_conflict, "Esas fechas ya están ocupadas. Elegí otro intervalo.")
          end
          reservation = user.reservations.create!(boat: boat, starts_on: request.starts_on, ends_on: request.ends_on,
            passengers: request.passengers, **quote.except(:days), idempotency_key: key, request_fingerprint: request.fingerprint)
          result = [reservation, true]
        end
      end
    end
    result
  rescue ActiveRecord::StatementInvalid => exception
    raise unless exception.cause.is_a?(PG::ExclusionViolation)
    raise ReservationError.new(:availability_conflict, "Esas fechas ya están ocupadas. Elegí otro intervalo.")
  end
end
