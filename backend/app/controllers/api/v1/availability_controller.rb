module Api
  module V1
    class AvailabilityController < BaseController
      skip_before_action :require_account!

      def show
        boat = Boat.published.find(params[:boat_id])
        request = ReservationRequest.new(params.permit(:starts_on, :ends_on, :passengers))
        boat.with_lock do
          raise ActiveRecord::RecordNotFound unless boat.active?
          request.validate_for_boat!(boat)
          intervals = boat.reservations.confirmed.overlapping(request.starts_on, request.ends_on)
            .order(:starts_on).limit(51).pluck(:starts_on, :ends_on)
          render json: { data: request.quote(boat).merge(available: intervals.empty?,
            occupied_intervals: intervals.first(50).map { |first, last| { starts_on: first, ends_on: last } },
            more_occupied_intervals: intervals.size > 50) }
        end
      end
    end
  end
end
