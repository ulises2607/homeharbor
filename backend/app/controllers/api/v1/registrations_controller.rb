module Api
  module V1
    class RegistrationsController < BaseController
      skip_before_action :require_account!
      rate_limit to: 5, within: 1.minute, store: RATE_LIMIT_STORE, with: :rate_limited

      def create
        account = User.new(params.expect(user: [:name, :email, :password, :password_confirmation]))
        account.name = account.name.to_s.strip
        account.save!
        render json: { data: { confirmation_required: true, message: "Revisá tu correo para confirmar la cuenta antes de ingresar." } }, status: :created
      end
    end
  end
end
