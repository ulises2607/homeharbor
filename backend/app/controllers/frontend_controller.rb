class FrontendController < ActionController::Base
  def index
    file = Rails.root.join("public/index.html")
    if file.exist?
      response.headers["Cache-Control"] = "no-cache"
      render file: file, layout: false, content_type: "text/html"
    else
      render plain: "Frontend not built. Use Vite in development.", status: :service_unavailable
    end
  end
end
