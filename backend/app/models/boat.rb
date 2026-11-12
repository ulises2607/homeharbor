class Boat < ApplicationRecord
  TIME_ZONE = "Etc/GMT+3" # IANA reverses the sign: this is a fixed UTC-03:00.
  MAX_PHOTOS = 5
  MAX_PHOTO_BYTES = 5.megabytes
  PHOTO_TYPES = %w[image/jpeg image/png image/webp].freeze

  belongs_to :owner, class_name: "User", inverse_of: :boats
  has_many_attached :photos
  validates :name, :description, :port, :time_zone, presence: true
  validates :name, :port, length: { maximum: 150 }
  validates :description, length: { maximum: 5000 }
  validates :capacity, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 500 }
  validates :daily_rate_cents, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 100_000_000 }
  validates :currency, inclusion: { in: %w[USD] }
  validates :time_zone, inclusion: { in: [TIME_ZONE] }
  scope :published, -> { where(active: true) }

  def public_details
    attributes.slice("id", "name", "description", "port", "time_zone", "capacity", "daily_rate_cents", "currency", "active").merge(
      "photos" => photos.sort_by(&:id).map { |photo| { id: photo.id, url: "/api/v1/boats/#{id}/photos/#{photo.id}" } }
    )
  end
end
