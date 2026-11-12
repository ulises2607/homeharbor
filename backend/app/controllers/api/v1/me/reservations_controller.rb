module Api
  module V1
    module Me
      class ReservationsController < BaseController
        def index
          render_reservations(current_account.reservations)
        end

        def show
          render json: { data: current_account.reservations.includes(:boat).find(params[:id]).details }
        end

        def cancellation
          reservation = current_account.reservations.find(params[:id])
          render json: { data: CancelReservation.call(reservation).details }
        end

        private

        def render_reservations(scope, owner_view: false)
          page = positive_integer_param(:page, 1)
          per_page = [positive_integer_param(:per_page, 12), 50].min
          records = scope.includes(:boat, :user).order(created_at: :desc, id: :desc).offset((page - 1) * per_page).limit(per_page)
          render json: { data: records.map { |record| record.details(owner_view: owner_view) },
            meta: { page: page, per_page: per_page, total: scope.count } }
        end
      end
    end
  end
end
