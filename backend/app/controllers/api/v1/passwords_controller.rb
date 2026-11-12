module Api
  module V1
    class PasswordsController < BaseController
      skip_before_action :require_account!
      rate_limit to: 5, within: 1.minute, store: RATE_LIMIT_STORE, with: :rate_limited

      def create
        User.send_reset_password_instructions(email: params.require(:email))
        render json: { data: { message: "Si el correo está registrado, recibirás las instrucciones." } }, status: :accepted
      end

      def update
        account = User.reset_password_by_token(params.permit(:reset_password_token, :password, :password_confirmation))
        return validation_error(account) if account.errors.any?
        reset_session
        render json: { data: { message: "Contraseña actualizada. Volvé a ingresar." } }
      end
    end
  end
end
