module Api
  module V1
    class BoatsController < BaseController
      skip_before_action :require_account!, only: %i[index show]

      def index
        scope = Boat.published
        raise ActionController::ParameterMissing, :port unless params[:port].nil? || params[:port].is_a?(String)
        port = params[:port].to_s.strip
        raise ActionController::ParameterMissing, :port if port.length > 150
        scope = scope.where("port ILIKE ?", "%#{Boat.sanitize_sql_like(port)}%") if port.present?
        if params[:min_capacity].present?
          capacity = Integer(params[:min_capacity].to_s, 10, exception: false)
          raise ActionController::ParameterMissing, :min_capacity unless capacity && capacity.between?(1, 500)
          scope = scope.where(capacity: capacity..)
        end
        render_collection(scope)
      end

      def show
        render json: { data: Boat.published.with_attached_photos.find(params[:id]).public_details }
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
        page = positive_integer_param(:page, 1)
        per_page = [positive_integer_param(:per_page, 12), 50].min
        render json: { data: scope.with_attached_photos.order(:id).offset((page - 1) * per_page).limit(per_page).map(&:public_details),
                       meta: { page: page, per_page: per_page, total: scope.count } }
      end

      def positive_integer_param(key, default)
        return default unless params.key?(key)
        value = Integer(params[key].to_s, 10, exception: false)
        raise ActionController::ParameterMissing, key unless value && value.between?(1, 1_000_000)
        value
      end
    end
  end
end
