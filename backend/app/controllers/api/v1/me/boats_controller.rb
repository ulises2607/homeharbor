module Api
  module V1
    module Me
      class BoatsController < Api::V1::BoatsController
        before_action :require_account!

        def index
          render_collection(current_account.boats)
        end

        def show
          render json: { data: current_account.boats.find(params[:id]).public_details }
        end
      end
    end
  end
end
