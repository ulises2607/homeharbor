require "test_helper"

class ReservationsTest < ActionDispatch::IntegrationTest
  PASSWORD = "Reservation-test-2026!"
  setup do
    Api::V1::BaseController.allow_forgery_protection = true
    Api::V1::BaseController::RATE_LIMIT_STORE.clear
    travel_to Time.utc(2026, 12, 1, 15)
    @owner = account("owner@reservation.test")
    @customer = account("customer@reservation.test")
    @other = account("other@reservation.test")
    @boat = @owner.boats.create!(name: "Aurora", description: "Demo", port: "Tigre", capacity: 6, daily_rate_cents: 10000)
  end
  teardown do
    travel_back
    Api::V1::BaseController.allow_forgery_protection = false
  end

  def account(email)
    User.new(name: "Demo", email: email, password: PASSWORD, password_confirmation: PASSWORD).tap do |user|
      user.skip_confirmation!
      user.save!
    end
  end
  def csrf(client = self)
    client.get "/api/v1/session/csrf", as: :json
    client.response.parsed_body.dig("data", "csrf_token")
  end
  def write(method, path, body = {}, client: self, key: nil)
    headers = { "X-CSRF-Token" => csrf(client) }
    headers["Idempotency-Key"] = key if key
    client.public_send(method, path, params: body, headers: headers, as: :json)
  end
  def login(user = @customer, client: self)
    write(:post, "/api/v1/session", { user: { email: user.email, password: PASSWORD } }, client: client)
    assert_equal 200, client.response.status
  end
  def attributes
    { boat_id: @boat.id, starts_on: "2026-12-10", ends_on: "2026-12-12", passengers: 4, expected_total_cents: 20000, expected_currency: "USD" }
  end
  def reserve(overrides = {}, key: SecureRandom.uuid, client: self, **changes)
    write(:post, "/api/v1/reservations", { reservation: attributes.merge(overrides).merge(changes) }, key: key, client: client)
  end

  test "quote is public prices in USD and shows no customer data" do
    get "/api/v1/boats/#{@boat.id}/availability", params: attributes.slice(:starts_on, :ends_on, :passengers)
    assert_response :success
    quote = response.parsed_body["data"]
    assert_equal true, quote["available"]
    assert_equal 2, quote["days"]
    assert_equal 20000, quote["total_cents"]
    assert_equal "Etc/GMT+3", quote["time_zone"]
    assert_equal [], quote["occupied_intervals"]
    assert_equal 0, Reservation.count
  end

  test "booking requires session CSRF and UUID idempotency key" do
    reserve
    assert_response :unauthorized
    login
    post "/api/v1/reservations", params: { reservation: attributes }, as: :json
    assert_response :unprocessable_entity
    reserve(key: "not-a-uuid")
    assert_response :bad_request
    assert_equal 0, Reservation.count
  end

  test "server assigns customer status and price and conserves the snapshot" do
    login
    reserve(user_id: @other.id, status: "cancelled", total_cents: 1, daily_rate_cents: 1)
    assert_response :created
    record = Reservation.find(response.parsed_body.dig("data", "id"))
    assert_equal @customer.id, record.user_id
    assert_equal "confirmed", record.status
    assert_equal 20000, record.total_cents
    assert_equal "2026-12-09T03:00:00Z", response.parsed_body.dig("data", "cancellation_deadline")
    assert_not response.parsed_body["data"].key?("request_fingerprint")
    @boat.update!(daily_rate_cents: 30000)
    assert_equal 20000, record.reload.total_cents
  end

  test "strict dates tomorrow in UTC minus three interval capacity and number shapes" do
    login
    [{ starts_on: "2026-12-01" }, { starts_on: "2026-02-30" }, { starts_on: "10/12/2026" },
      { ends_on: "2026-12-10" }, { ends_on: "2026-12-09" }, { passengers: 7 },
      { passengers: "4people" }, { passengers: 1.5 }, { passengers: [2] }, { expected_total_cents: nil }].each do |invalid|
      assert_no_difference "Reservation.count" do
        reserve(invalid)
        assert_response :unprocessable_entity
      end
    end
    # At 02:59 UTC it is still December 1 in UTC-3; December 2 is a future day.
    travel_to Time.utc(2026, 12, 2, 2, 59)
    login
    reserve(starts_on: "2026-12-02", ends_on: "2026-12-03", expected_total_cents: 10000)
    assert_response :created
  end

  test "own inactive and missing boats cannot be booked" do
    login(@owner)
    reserve
    assert_response :forbidden
    login
    @boat.update!(active: false)
    reserve
    assert_response :not_found
    reserve(boat_id: 9_000_000)
    assert_response :not_found
    assert_equal 0, Reservation.count
  end

  test "changed price or currency requires a new quote" do
    login
    reserve(expected_total_cents: 1)
    assert_response :conflict
    assert_equal "price_changed", response.parsed_body.dig("error", "code")
    reserve(expected_currency: "EUR")
    assert_response :conflict
    assert_equal 0, Reservation.count
  end

  test "overlap is rejected contiguous days accepted and occupied intervals remain anonymous" do
    login
    reserve
    assert_response :created
    reserve(starts_on: "2026-12-11", ends_on: "2026-12-13")
    assert_response :conflict
    assert_equal "availability_conflict", response.parsed_body.dig("error", "code")
    get "/api/v1/boats/#{@boat.id}/availability", params: { starts_on: "2026-12-11", ends_on: "2026-12-13", passengers: 2 }
    assert_equal false, response.parsed_body.dig("data", "available")
    assert_equal [{ "starts_on" => "2026-12-10", "ends_on" => "2026-12-12" }], response.parsed_body.dig("data", "occupied_intervals")
    reserve(starts_on: "2026-12-12", ends_on: "2026-12-13", expected_total_cents: 10000)
    assert_response :created
    assert_equal 2, Reservation.count
  end

  test "same key replays before changed price publication or date rules and rejects changed inputs" do
    login
    key = SecureRandom.uuid
    reserve(key: key)
    id = response.parsed_body.dig("data", "id")
    @boat.update!(active: false, daily_rate_cents: 12000)
    travel_to Time.utc(2026, 12, 20)
    login
    reserve(key: key)
    assert_response :ok
    assert_equal id, response.parsed_body.dig("data", "id")
    reserve({ passengers: 3 }, key: key)
    assert_response :conflict
    assert_equal "idempotency_conflict", response.parsed_body.dig("error", "code")
    assert_equal 1, Reservation.count
  end

  test "customer and owner have scoped history even after deactivation" do
    login
    reserve
    id = response.parsed_body.dig("data", "id")
    @boat.update!(active: false)
    get "/api/v1/me/reservations/#{id}"
    assert_response :success
    get "/api/v1/me/reservations?per_page=1"
    assert_equal 1, response.parsed_body.dig("meta", "total")
    other_browser = open_session
    login(@other, client: other_browser)
    other_browser.get "/api/v1/me/reservations/#{id}"
    assert_equal 404, other_browser.response.status
    write(:post, "/api/v1/me/reservations/#{id}/cancellation", client: other_browser)
    assert_equal 404, other_browser.response.status
    other_browser.get "/api/v1/me/boats/#{@boat.id}/reservations"
    assert_equal 404, other_browser.response.status
    login(@owner, client: other_browser)
    other_browser.get "/api/v1/me/boats/#{@boat.id}/reservations"
    assert_equal 200, other_browser.response.status
    assert_equal({ "name" => @customer.name }, other_browser.response.parsed_body["data"].first["customer"])
    write(:post, "/api/v1/me/reservations/#{id}/cancellation", client: other_browser)
    assert_equal 404, other_browser.response.status
  end

  test "cancel at exact cutoff frees dates preserves history and replays cancelled state" do
    login
    key = SecureRandom.uuid
    reserve(key: key)
    id = response.parsed_body.dig("data", "id")
    travel_to Time.utc(2026, 12, 9, 3)
    login
    write(:post, "/api/v1/me/reservations/#{id}/cancellation")
    assert_response :success
    assert_equal "cancelled", response.parsed_body.dig("data", "status")
    cancelled_at = Reservation.find(id).cancelled_at
    travel 2.days
    login
    write(:post, "/api/v1/me/reservations/#{id}/cancellation")
    assert_response :success
    assert_equal cancelled_at, Reservation.find(id).cancelled_at
    reserve(key: key)
    assert_response :ok
    assert_equal "cancelled", response.parsed_body.dig("data", "status")
    travel_back
    travel_to Time.utc(2026, 12, 9, 3)
    login
    reserve
    assert_response :created
    assert_equal 2, Reservation.count
  end

  test "one second after the cancellation cutoff leaves the reservation confirmed" do
    login
    reserve
    id = response.parsed_body.dig("data", "id")
    travel_to Time.utc(2026, 12, 9, 3, 0, 1)
    login
    write(:post, "/api/v1/me/reservations/#{id}/cancellation")
    assert_response :conflict
    assert_equal "cancellation_closed", response.parsed_body.dig("error", "code")
    assert_equal "confirmed", Reservation.find(id).status
  end

  test "owner cannot reduce capacity below active reservations or erase their history" do
    login
    reserve
    login(@owner)
    write(:patch, "/api/v1/boats/#{@boat.id}", { boat: { capacity: 3 } })
    assert_response :unprocessable_entity
    assert_equal 6, @boat.reload.capacity
    write(:post, "/api/v1/boats/#{@boat.id}/deactivation")
    assert_response :success
    assert_equal "confirmed", Reservation.first.status
    assert_not @boat.destroy
    assert_not @customer.reload.destroy
  end

  test "PostgreSQL independently enforces overlap price status and idempotency uniqueness" do
    login
    reserve
    existing = Reservation.first
    row = existing.attributes.except("id").merge("idempotency_key" => SecureRandom.uuid)
    error = assert_raises(ActiveRecord::StatementInvalid) do
      Reservation.transaction(requires_new: true) { Reservation.insert_all!([row]) }
    end
    assert_instance_of PG::ExclusionViolation, error.cause
    [{ "total_cents" => 1 }, { "status" => "fake" }, { "passengers" => 0 }].each do |invalid|
      assert_raises(ActiveRecord::StatementInvalid) do
        Reservation.transaction(requires_new: true) { Reservation.where(id: existing.id).update_all(invalid) }
      end
    end
    assert_raises(ActiveRecord::RecordNotUnique) do
      Reservation.transaction(requires_new: true) do
        Reservation.insert_all!([row.merge("idempotency_key" => existing.idempotency_key, "starts_on" => Date.new(2026, 12, 20), "ends_on" => Date.new(2026, 12, 22))])
      end
    end
  end
end
