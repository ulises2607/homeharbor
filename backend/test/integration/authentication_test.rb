require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  PASSWORD = "Harbor-test-password-2026!"

  setup do
    Api::V1::BaseController.allow_forgery_protection = true
    Api::V1::BaseController::RATE_LIMIT_STORE.clear
    ActionMailer::Base.deliveries.clear
  end

  teardown do
    Api::V1::BaseController.allow_forgery_protection = false
  end

  def create_account(email: "owner@example.com", confirmed: true)
    account = User.new(name: "Test owner", email: email, password: PASSWORD, password_confirmation: PASSWORD)
    account.skip_confirmation! if confirmed
    account.save!
    account
  end

  def csrf(client = self)
    client.get "/api/v1/session/csrf", as: :json
    client.response.parsed_body.dig("data", "csrf_token")
  end

  def request_json(method, path, body = {}, client: self)
    token = csrf(client)
    client.public_send(method, path, params: body, headers: { "X-CSRF-Token" => token }, as: :json)
  end

  def login_account(account, client: self, password: PASSWORD)
    request_json(:post, "/api/v1/session", { user: { email: account.email, password: password } }, client: client)
  end

  def boat_attributes
    { name: "Harbor One", description: "A small sailing boat", port: "Tigre", capacity: 6,
      daily_rate_cents: 10000, currency: "USD", time_zone: "Etc/GMT+3" }
  end

  test "registration requires CSRF and cannot inject confirmation or privileges" do
    user = { name: "Ana", email: "ana@example.com", password: PASSWORD, password_confirmation: PASSWORD,
             role: "admin", confirmed_at: Time.current }
    assert_no_difference "User.count" do
      post "/api/v1/registrations", params: { user: user }, as: :json
    end
    assert_response :unprocessable_entity
    assert_equal "invalid_csrf", response.parsed_body.dig("error", "code")

    assert_difference "User.count", 1 do
      assert_emails 1 do
        request_json(:post, "/api/v1/registrations", { user: user })
      end
    end
    assert_response :created
    assert_not User.find_by!(email: user[:email]).confirmed?
    get "/api/v1/session", as: :json
    assert_response :unauthorized
    mail = ActionMailer::Base.deliveries.last
    assert_includes mail.body.decoded, "http://127.0.0.1:5173/confirm-email?confirmation_token="
  end

  test "invalid registration reports fields and does not claim success" do
    request_json(:post, "/api/v1/registrations", { user: { name: "", email: "invalid", password: "short", password_confirmation: "other" } })
    assert_response :unprocessable_entity
    assert response.parsed_body.dig("error", "fields", "email").present?
    assert response.parsed_body.dig("error", "fields", "password").present?
  end

  test "malformed parameter shapes return JSON instead of internal errors" do
    request_json(:post, "/api/v1/session", { user: "invalid" })
    assert_response :bad_request
    assert_equal "invalid_request", response.parsed_body.dig("error", "code")
    request_json(:post, "/api/v1/registrations", { user: [{ email: "invalid@example.com" }] })
    assert_response :bad_request
    login_account(create_account)
    request_json(:post, "/api/v1/boats", { boat: "invalid" })
    assert_response :bad_request
  end

  test "confirmation link activates account once and does not automatically sign in" do
    account = create_account(confirmed: false)
    raw_token = ActionMailer::Base.deliveries.last.body.decoded.match(/confirmation_token=([^"<\s]+)/)[1]
    request_json(:patch, "/api/v1/confirmations", { confirmation_token: raw_token })
    assert_response :success
    assert account.reload.confirmed?
    get "/api/v1/session", as: :json
    assert_response :unauthorized
    request_json(:patch, "/api/v1/confirmations", { confirmation_token: raw_token })
    assert_response :unprocessable_entity
  end

  test "unconfirmed and wrong-password logins fail without leaking user data" do
    account = create_account(confirmed: false)
    login_account(account)
    assert_response :unauthorized
    account.confirm
    login_account(account, password: "incorrect")
    assert_response :unauthorized
    assert_nil response.parsed_body["data"]
    request_json(:post, "/api/v1/session", { user: { name: account.name } })
    assert_response :bad_request
  end

  test "login restores identity and rotates CSRF; logout invalidates the session" do
    account = create_account
    old_csrf = csrf
    post "/api/v1/session", params: { user: { email: account.email, password: PASSWORD } },
      headers: { "X-CSRF-Token" => old_csrf }, as: :json
    assert_response :success
    assert_equal account.id, response.parsed_body.dig("data", "user", "id")
    assert_equal %w[email id name], response.parsed_body.dig("data", "user").keys.sort
    assert_includes response.headers["Set-Cookie"].downcase, "httponly"
    assert_includes response.headers["Set-Cookie"].downcase, "samesite=lax"
    get "/api/v1/session", as: :json
    assert_response :success
    assert_equal "no-store", response.headers["Cache-Control"]
    delete "/api/v1/session", headers: { "X-CSRF-Token" => old_csrf }, as: :json
    assert_response :unprocessable_entity
    request_json(:delete, "/api/v1/session")
    assert_response :no_content
    get "/api/v1/session", as: :json
    assert_response :unauthorized
    request_json(:delete, "/api/v1/session")
    assert_response :no_content
  end

  test "cross-origin changes are rejected even with a valid CSRF token" do
    token = csrf
    post "/api/v1/session", params: { user: { email: "someone@example.com", password: PASSWORD } },
      headers: { "X-CSRF-Token" => token, "Origin" => "https://untrusted.example" }, as: :json
    assert_response :unprocessable_entity
  end

  test "five failed attempts lock an account temporarily" do
    account = create_account
    5.times { login_account(account, password: "wrong") }
    assert account.reload.access_locked?
    login_account(account)
    assert_response :unauthorized
    travel 31.minutes do
      login_account(account)
      assert_response :success
      assert_not account.reload.access_locked?
    end
  end

  test "login limits requests by IP with a JSON response" do
    11.times { request_json(:post, "/api/v1/session", { user: { email: "absent@example.com", password: PASSWORD } }) }
    assert_response :too_many_requests
    assert_equal "rate_limited", response.parsed_body.dig("error", "code")
    assert_equal "60", response.headers["Retry-After"]
  end

  test "sessions expire after 30 idle minutes" do
    login_account(create_account)
    travel 31.minutes do
      get "/api/v1/session", as: :json
      assert_response :unauthorized
    end
  end

  test "active sessions still expire after twelve hours" do
    login_account(create_account)
    start = Time.current
    35.times do |index|
      travel_to(start + (index + 1) * 20.minutes)
      get "/api/v1/session", as: :json
      assert_response :success
    end
    travel_to(start + 12.hours)
    get "/api/v1/session", as: :json
    assert_response :unauthorized
  ensure
    travel_back
  end

  test "reset and confirmation requests do not enumerate existing accounts" do
    account = create_account
    %w[passwords confirmations].each do |resource|
      request_json(:post, "/api/v1/#{resource}", { email: account.email })
      assert_response :accepted
      existing = response.parsed_body
      request_json(:post, "/api/v1/#{resource}", { email: "missing@example.com" })
      assert_response :accepted
      assert_equal existing, response.parsed_body
    end
  end

  test "password reset is one-use and revokes an existing session" do
    account = create_account
    second_browser = open_session
    login_account(account, client: second_browser)
    request_json(:post, "/api/v1/passwords", { email: account.email })
    token = ActionMailer::Base.deliveries.last.body.decoded.match(/reset_password_token=([^"<\s]+)/)[1]
    replacement = PASSWORD + "-changed"
    request_json(:patch, "/api/v1/passwords", { reset_password_token: token, password: replacement, password_confirmation: replacement })
    assert_response :success
    second_browser.get "/api/v1/session", as: :json
    assert_equal 401, second_browser.response.status
    login_account(account, password: PASSWORD)
    assert_response :unauthorized
    login_account(account, password: replacement)
    assert_response :success
    request_json(:patch, "/api/v1/passwords", { reset_password_token: token, password: replacement, password_confirmation: replacement })
    assert_response :unprocessable_entity
  end

  test "anonymous clients cannot create or view private boats" do
    get "/api/v1/me/boats", as: :json
    assert_response :unauthorized
    request_json(:post, "/api/v1/boats", { boat: boat_attributes })
    assert_response :unauthorized
    get "/api/v1/boats", as: :json
    assert_response :success
  end

  test "ownership comes from session and protects reads edits and deactivation" do
    owner = create_account
    other = create_account(email: "other@example.com")
    login_account(owner)
    request_json(:post, "/api/v1/boats", { boat: boat_attributes.merge(owner_id: other.id, user_id: other.id, active: false) })
    assert_response :created
    boat = Boat.find(response.parsed_body.dig("data", "id"))
    assert_equal owner.id, boat.owner_id
    assert boat.active?
    get "/api/v1/boats/#{boat.id}", as: :json
    assert_response :success
    assert_nil response.parsed_body.dig("data", "owner_id")

    other_browser = open_session
    login_account(other, client: other_browser)
    other_browser.get "/api/v1/me/boats", as: :json
    assert_equal [], other_browser.response.parsed_body["data"]
    other_browser.get "/api/v1/me/boats/#{boat.id}", as: :json
    assert_equal 404, other_browser.response.status
    request_json(:patch, "/api/v1/boats/#{boat.id}", { boat: { name: "Stolen" } }, client: other_browser)
    assert_equal 404, other_browser.response.status
    request_json(:post, "/api/v1/boats/#{boat.id}/deactivation", {}, client: other_browser)
    assert_equal 404, other_browser.response.status
    assert_equal "Harbor One", boat.reload.name
    assert boat.active?

    request_json(:patch, "/api/v1/boats/#{boat.id}", { boat: { name: "Updated" } })
    assert_response :success
    request_json(:post, "/api/v1/boats/#{boat.id}/deactivation")
    assert_response :success
    assert_not boat.reload.active?
    get "/api/v1/boats/#{boat.id}", as: :json
    assert_response :not_found
    get "/api/v1/me/boats/#{boat.id}", as: :json
    assert_response :success
    assert_equal "Updated", response.parsed_body.dig("data", "name")
    request_json(:post, "/api/v1/boats/#{boat.id}/activation")
    assert_response :success
    assert boat.reload.active?
  end

  test "invalid boats do not persist and catalog is paginated" do
    account = create_account
    login_account(account)
    assert_no_difference "Boat.count" do
      request_json(:post, "/api/v1/boats", { boat: boat_attributes.merge(capacity: 0, daily_rate_cents: -10) })
    end
    assert_response :unprocessable_entity
    13.times { |index| account.boats.create!(boat_attributes.merge(name: "Boat #{index}")) }
    get "/api/v1/boats?page=2", as: :json
    assert_response :success
    assert_equal 1, response.parsed_body["data"].size
    assert_equal 13, response.parsed_body.dig("meta", "total")
  end

  test "parallel HTML authentication and insecure original endpoints are absent" do
    ["/users/sign_in", "/login", "/signup", "/api/v1/users"].each do |path|
      assert_raises(ActionController::RoutingError) { Rails.application.routes.recognize_path(path) }
    end
  end
end
