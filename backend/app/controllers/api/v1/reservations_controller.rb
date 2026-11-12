module Api
  module V1
    class ReservationsController < BaseController
      def create
        attributes = params.expect(reservation: [:boat_id, :starts_on, :ends_on, :passengers, :expected_total_cents, :expected_currency])
        reservation, created = CreateReservation.call(user: current_account, attributes: attributes,
          idempotency_key: request.headers["Idempotency-Key"])
        render json: { data: reservation.details }, status: created ? :created : :ok
      end
    end
  end
end
