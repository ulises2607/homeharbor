module Api
  module V1
    module Me
      class BoatReservationsController < ReservationsController
        def index
          boat = current_account.boats.find(params[:boat_id])
          render_reservations(boat.reservations, owner_view: true)
        end
      end
    end
  end
end
