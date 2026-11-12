module Api
  module V1
    class BoatPhotosController < BaseController
      skip_before_action :require_account!, only: :show

      rescue_from BoatPhotoUpload::InvalidUpload do |exception|
        api_error(:invalid_photo, exception.message, :unprocessable_entity)
      end
      rescue_from ActiveStorage::FileNotFoundError do
        api_error(:not_found, "No se encontró la foto.", :not_found)
      end
      rescue_from IOError, SystemCallError, ActiveStorage::IntegrityError do |exception|
        Rails.logger.error("Photo storage unavailable: #{exception.class}")
        api_error(:storage_unavailable, "No pudimos acceder a la foto. Volvé a intentarlo.", :service_unavailable)
      end

      def show
        boat = Boat.find(params[:boat_id])
        raise ActiveRecord::RecordNotFound unless boat.active? || current_account&.id == boat.owner_id
        photo = boat.photos.find(params[:id])
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["Content-Security-Policy"] = "default-src 'none'; sandbox"
        send_data photo.download, type: photo.content_type, disposition: "inline", filename: photo.filename.to_s
        response.headers["Cache-Control"] = "no-store"
      end

      def create
        boat = current_account.boats.find(params[:boat_id])
        render json: { data: BoatPhotoUpload.call(boat, params[:photo]) }, status: :created
      end

      def destroy
        boat = current_account.boats.find(params[:boat_id])
        boat.with_lock { boat.photos.find(params[:id]).purge }
        head :no_content
      end
    end
  end
end
