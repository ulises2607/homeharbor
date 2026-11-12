module Api
  module V1
    class SessionsController < BaseController
      skip_before_action :require_account!, except: :show
      rate_limit to: 10, within: 1.minute, only: :create, store: RATE_LIMIT_STORE, with: :rate_limited

      def csrf
        render json: { data: { csrf_token: form_authenticity_token } }
      end

      def show
        render json: { data: { user: current_account.public_profile, csrf_token: form_authenticity_token } }
      end

      def create
        credentials = params.expect(user: [:email, :password])
        account = User.find_for_database_authentication(email: credentials[:email].to_s.strip.downcase)
        password = credentials[:password].to_s
        valid = account&.valid_for_authentication? { account.valid_password?(password) }
        User.new.password = password unless account # Similar cost for unknown accounts.
        unless valid && account.active_for_authentication?
          return api_error(:invalid_credentials, "No pudimos ingresar. Revisá correo y contraseña, confirmá tu correo o intentá más tarde.", :unauthorized)
        end

        account.reset_failed_attempts!
        reset_session
        session[:account_id] = account.id
        session[:auth_salt] = account.authenticatable_salt
        session[:signed_in_at] = session[:last_seen_at] = Time.current.to_i
        render json: { data: { user: account.public_profile, csrf_token: form_authenticity_token } }
      end

      def destroy
        reset_session
        head :no_content
      end
    end
  end
end
