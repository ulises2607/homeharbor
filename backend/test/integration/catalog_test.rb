require "test_helper"

class CatalogTest < ActionDispatch::IntegrationTest
  PASSWORD = "Catalog-test-password-2026!"
  PNG = Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jZ1cAAAAASUVORK5CYII=").freeze

  setup do
    Api::V1::BaseController.allow_forgery_protection = true
    Api::V1::BaseController::RATE_LIMIT_STORE.clear
    @owner = account("owner@catalog.test")
    @other = account("other@catalog.test")
    @boat = @owner.boats.create!(name: "Aurora", description: "Demo boat", port: "Tigre", capacity: 6, daily_rate_cents: 12000)
    @storage_keys = []
  end

  teardown do
    @storage_keys.each { |key| ActiveStorage::Blob.service.delete(key) }
    Api::V1::BaseController.allow_forgery_protection = false
  end

  def account(email)
    User.new(name: "Demo owner", email: email, password: PASSWORD, password_confirmation: PASSWORD).tap do |user|
      user.skip_confirmation!
      user.save!
    end
  end

  def csrf(client = self)
    client.get "/api/v1/session/csrf", as: :json
    client.response.parsed_body.dig("data", "csrf_token")
  end

  def login(user = @owner, client: self)
    client.post "/api/v1/session", params: { user: { email: user.email, password: PASSWORD } },
      headers: { "X-CSRF-Token" => csrf(client) }, as: :json
    assert_equal 200, client.response.status
  end

  def upload(bytes = PNG, type: "image/png", client: self, boat: @boat)
    file = Tempfile.new(["boat-photo", ".png"], binmode: true)
    file.write(bytes)
    file.rewind
    client.post "/api/v1/boats/#{boat.id}/photos", params: { photo: Rack::Test::UploadedFile.new(file.path, type, true) },
      headers: { "X-CSRF-Token" => csrf(client) }
    @storage_keys |= ActiveStorage::Blob.pluck(:key)
  ensure
    file&.close!
  end

  test "public filters intersect before pagination and hide inactive boats" do
    @owner.boats.create!(@boat.attributes.except("id", "created_at", "updated_at").merge(name: "Small", capacity: 2))
    @owner.boats.create!(@boat.attributes.except("id", "created_at", "updated_at").merge(name: "Hidden", active: false))
    get "/api/v1/boats", params: { port: "  tIg  ", min_capacity: 4, per_page: 1 }
    assert_response :success
    assert_equal [@boat.id], response.parsed_body["data"].map { |boat| boat["id"] }
    assert_equal 1, response.parsed_body.dig("meta", "total")
    get "/api/v1/boats", params: { port: "%" }
    assert_equal [], response.parsed_body["data"]
  end

  test "malformed filters and pagination return JSON errors" do
    [{ port: ["Tigre"] }, { port: "x" * 151 }, { min_capacity: "1.5" }, { min_capacity: 0 },
      { min_capacity: 501 }, { page: [1] }, { per_page: "bad" }].each do |filters|
      get "/api/v1/boats", params: filters
      assert_response :bad_request
      assert_equal "invalid_request", response.parsed_body.dig("error", "code")
    end
  end

  test "USD and UTC minus three are enforced in model and database" do
    assert_equal "USD", @boat.currency
    assert_equal "Etc/GMT+3", @boat.time_zone
    [Time.utc(2026, 1, 10), Time.utc(2026, 7, 10)].each do |instant|
      assert_equal(-10800, instant.in_time_zone(@boat.time_zone).utc_offset)
    end
    assert_not @boat.update(currency: "ARS", time_zone: "UTC")
    assert_raises(ActiveRecord::StatementInvalid) do
      Boat.transaction(requires_new: true) { Boat.where(id: @boat.id).update_all(currency: "ARS") }
    end
  end

  test "owner uploads photo served publicly with bytes verified and no signed bypass" do
    login
    upload(PNG, type: "application/octet-stream")
    assert_response :created
    photo = response.parsed_body.dig("data", "photos").first
    assert photo["url"].start_with?("/api/v1/boats/#{@boat.id}/photos/")
    guest = open_session
    guest.get photo["url"]
    assert_equal 200, guest.response.status
    assert_equal "image/png", guest.response.media_type
    assert_equal PNG, guest.response.body.b
    assert_equal "no-store", guest.response.headers["Cache-Control"]
    assert_equal "nosniff", guest.response.headers["X-Content-Type-Options"]
    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/rails/active_storage/blobs/redirect/fake/photo.png")
    end
    get "/api/v1/boats"
    assert_equal [photo], response.parsed_body["data"].first["photos"]
  end

  test "unpublished photos are visible only to their owner even with an old URL" do
    login
    upload
    path = response.parsed_body.dig("data", "photos").first["url"]
    @boat.update!(active: false)
    get path
    assert_response :success
    guest = open_session
    guest.get path
    assert_equal 404, guest.response.status
    login(@other, client: guest)
    guest.get path
    assert_equal 404, guest.response.status
  end

  test "anonymous clients and other owners cannot upload or delete photos" do
    upload
    assert_response :unauthorized
    login
    upload
    photo = @boat.photos.first
    other_client = open_session
    login(@other, client: other_client)
    assert_no_difference "ActiveStorage::Attachment.count" do
      upload(client: other_client)
      assert_equal 404, other_client.response.status
      other_client.delete "/api/v1/boats/#{@boat.id}/photos/#{photo.id}", headers: { "X-CSRF-Token" => csrf(other_client) }
      assert_equal 404, other_client.response.status
    end
    # Owner of a different boat cannot use its URL to delete this attachment.
    another_boat = @other.boats.create!(name: "Other", description: "Another", port: "Tigre", capacity: 2, daily_rate_cents: 1000)
    other_client.delete "/api/v1/boats/#{another_boat.id}/photos/#{photo.id}", headers: { "X-CSRF-Token" => csrf(other_client) }
    assert_equal 404, other_client.response.status
    delete "/api/v1/boats/#{@boat.id}/photos/#{photo.id}"
    assert_response :unprocessable_entity
    assert_difference "ActiveStorage::Attachment.count", -1 do
      delete "/api/v1/boats/#{@boat.id}/photos/#{photo.id}", headers: { "X-CSRF-Token" => csrf }
      assert_response :no_content
    end
    get "/api/v1/boats/#{@boat.id}/photos/#{photo.id}"
    assert_response :not_found
  end

  test "forged MIME oversized empty and malformed uploads leave no blobs" do
    login
    assert_no_difference ["ActiveStorage::Blob.count", "ActiveStorage::Attachment.count"] do
      ["<svg xmlns='http://www.w3.org/2000/svg'></svg>", "", PNG + ("x" * Boat::MAX_PHOTO_BYTES)].each do |bytes|
        upload(bytes)
        assert_response :unprocessable_entity
      end
      post "/api/v1/boats/#{@boat.id}/photos", params: { photo: "not-a-file" }, headers: { "X-CSRF-Token" => csrf }
      assert_response :unprocessable_entity
    end
  end

  test "maximum five photos rejects a sixth without leaving an orphan" do
    login
    5.times { upload; assert_response :created }
    assert_no_difference ["ActiveStorage::Blob.count", "ActiveStorage::Attachment.count"] do
      upload
      assert_response :unprocessable_entity
      assert_includes response.parsed_body.dig("error", "message"), "5 fotos"
    end
  end

  test "storage upload failure rolls back records and reports a retryable error" do
    login
    service = ActiveStorage::Blob.service
    service.define_singleton_method(:upload) { |*| raise IOError, "simulated disk failure" }
    assert_no_difference ["ActiveStorage::Blob.count", "ActiveStorage::Attachment.count"] do
      upload
      assert_response :service_unavailable
      assert_equal "storage_unavailable", response.parsed_body.dig("error", "code")
    end
  ensure
    service&.singleton_class&.remove_method(:upload)
  end

  test "missing stored file returns JSON not an internal error" do
    login
    upload
    photo = @boat.photos.first
    photo.blob.service.delete(photo.key)
    get "/api/v1/boats/#{@boat.id}/photos/#{photo.id}"
    assert_response :not_found
    assert_equal "not_found", response.parsed_body.dig("error", "code")
  end
end
