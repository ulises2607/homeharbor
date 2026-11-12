module Api
  module V1
    class BaseController < ApplicationController
      protect_from_forgery with: :exception
      before_action :private_response
      before_action :require_account!

      # Per-process protection. A shared store or edge limit is required for multiple processes.
      RATE_LIMIT_STORE = ActiveSupport::Cache::MemoryStore.new

      rescue_from ActionController::InvalidAuthenticityToken do
        api_error(:invalid_csrf, "La sesión del formulario venció. Volvé a intentarlo.", :unprocessable_entity)
      end
      rescue_from ActionController::ParameterMissing do
        api_error(:invalid_request, "Faltan datos obligatorios.", :bad_request)
      end
      rescue_from ActiveRecord::RecordNotFound do
        api_error(:not_found, "No se encontró el recurso.", :not_found)
      end
      rescue_from ActiveRecord::RecordInvalid do |exception|
        validation_error(exception.record)
      end
      rescue_from ActiveRecord::RecordNotUnique do
        api_error(:conflict, "Los datos ya existen. Revisalos e intentá nuevamente.", :conflict)
      end

      private

      def private_response
        response.headers["Cache-Control"] = "no-store"
      end

      def current_account
        return @current_account if defined?(@current_account)
        @current_account = nil
        return unless session[:account_id]

        account = User.find_by(id: session[:account_id])
        valid = account&.active_for_authentication? &&
          session[:signed_in_at].to_i > 12.hours.ago.to_i &&
          session[:last_seen_at].to_i > 30.minutes.ago.to_i &&
          ActiveSupport::SecurityUtils.secure_compare(session[:auth_salt].to_s, account.authenticatable_salt.to_s)
        unless valid
          reset_session
          return
        end
        session[:last_seen_at] = Time.current.to_i
        @current_account = account
      end

      def require_account!
        api_error(:unauthenticated, "Ingresá para continuar.", :unauthorized) unless current_account
      end

      def api_error(code, message, status, fields = nil)
        response.headers["Cache-Control"] = "no-store"
        error = { code: code, message: message }
        error[:fields] = fields if fields
        render json: { error: error }, status: status
      end

      def validation_error(record)
        api_error(:validation_failed, "Revisá los datos del formulario.", :unprocessable_entity, record.errors.to_hash)
      end

      def rate_limited
        response.headers["Retry-After"] = "60"
        api_error(:rate_limited, "Demasiados intentos. Esperá un minuto.", :too_many_requests)
      end
    end
  end
end
