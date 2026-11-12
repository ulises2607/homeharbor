require "test_helper"

class BoatPhotoConcurrencyTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  test "two concurrent uploads cannot both claim the fifth photo slot" do
    owner = User.new(name: "Concurrency demo", email: "photos-#{SecureRandom.hex(8)}@example.test",
      password: "Concurrent-photo-test-2026!", password_confirmation: "Concurrent-photo-test-2026!")
    owner.skip_confirmation!
    owner.save!
    boat = owner.boats.create!(name: "Concurrent", description: "Test boat", port: "Tigre", capacity: 4, daily_rate_cents: 1000)
    4.times { attach_photo(boat) }
    ready = Queue.new
    start = Queue.new
    threads = 2.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          own_instance = Boat.find(boat.id)
          ready << true
          start.pop
          begin
            attach_photo(own_instance)
            :created
          rescue BoatPhotoUpload::InvalidUpload
            :rejected
          end
        end
      end
    end
    2.times { ready.pop }
    2.times { start << true }
    assert_equal [:created, :rejected], threads.map(&:value).sort
    assert_equal 5, boat.reload.photos.count
  ensure
    threads&.each(&:join)
    if boat&.persisted?
      boat.photos.each(&:purge)
      boat.destroy!
    end
    owner.reload.destroy! if owner&.persisted?
  end

  def attach_photo(boat)
    file = Tempfile.new(["photo", ".png"], binmode: true)
    file.write(Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jZ1cAAAAASUVORK5CYII="))
    file.rewind
    BoatPhotoUpload.call(boat, ActionDispatch::Http::UploadedFile.new(tempfile: file, filename: "photo.png", type: "image/png"))
  ensure
    file&.close!
  end
end
