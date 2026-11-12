module Api
  module V1
    class ConfirmationsController < BaseController
      skip_before_action :require_account!
      rate_limit to: 5, within: 1.minute, store: RATE_LIMIT_STORE, with: :rate_limited

      def create
        User.send_confirmation_instructions(email: params.require(:email))
        render json: { data: { message: "Si el correo necesita confirmación, recibirás las instrucciones." } }, status: :accepted
      end

      def update
        account = User.confirm_by_token(params.require(:confirmation_token))
        return api_error(:invalid_token, "El enlace no es válido o venció. Pedí uno nuevo.", :unprocessable_entity) if account.errors.any?
        render json: { data: { message: "Correo confirmado. Ya podés ingresar." } }
      end
    end
  end
end
