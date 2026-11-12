class Boat < ApplicationRecord
  belongs_to :owner, class_name: "User", inverse_of: :boats
  validates :name, :description, :port, :time_zone, presence: true
  validates :name, :port, length: { maximum: 150 }
  validates :description, length: { maximum: 5000 }
  validates :capacity, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 500 }
  validates :daily_rate_cents, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 100_000_000 }
  validates :currency, inclusion: { in: %w[USD] }
  validates :time_zone, inclusion: { in: TZInfo::Timezone.all_identifiers }
  scope :published, -> { where(active: true) }

  def public_details
    attributes.slice("id", "name", "description", "port", "time_zone", "capacity", "daily_rate_cents", "currency", "active")
  end
end
