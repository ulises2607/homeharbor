class AccountMailer < Devise::Mailer
  helper_method :account_link

  def account_link(path, key, token)
    origin = ENV.fetch("FRONTEND_URL") { Rails.env.production? ? raise("FRONTEND_URL is required") : "http://127.0.0.1:5173" }
    "#{origin.delete_suffix('/')}/#{path}?#{key}=#{ERB::Util.url_encode(token)}"
  end
end
