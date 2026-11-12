module Api
  module V1
    class BoatsController < BaseController
      skip_before_action :require_account!, only: %i[index show]

      def index
        render_collection(Boat.published)
      end

      def show
        render json: { data: Boat.published.find(params[:id]).public_details }
      end

      def create
        boat = current_account.boats.create!(boat_params)
        render json: { data: boat.public_details }, status: :created
      end

      def update
        boat = current_account.boats.find(params[:id])
        boat.update!(boat_params)
        render json: { data: boat.public_details }
      end

      def deactivation
        set_publication(false)
      end

      def activation
        set_publication(true)
      end

      private

      def set_publication(active)
        boat = current_account.boats.find(params[:id])
        boat.update!(active: active)
        render json: { data: boat.public_details }
      end

      def boat_params
        params.expect(boat: [:name, :description, :port, :time_zone, :capacity, :daily_rate_cents, :currency])
      end

      def render_collection(scope)
        page = [params[:page].to_i, 1].max
        per_page = params[:per_page].present? ? params[:per_page].to_i.clamp(1, 50) : 12
        render json: { data: scope.order(:id).offset((page - 1) * per_page).limit(per_page).map(&:public_details),
                       meta: { page: page, per_page: per_page, total: scope.count } }
      end
    end
  end
end
