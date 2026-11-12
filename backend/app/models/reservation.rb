class Reservation < ApplicationRecord
  belongs_to :user
  belongs_to :boat
  attr_readonly :user_id, :boat_id, :starts_on, :ends_on, :passengers, :daily_rate_cents,
    :total_cents, :currency, :time_zone, :idempotency_key, :request_fingerprint

  validates :starts_on, :ends_on, :idempotency_key, :request_fingerprint, presence: true
  validates :status, inclusion: { in: %w[confirmed cancelled] }
  validates :currency, inclusion: { in: ["USD"] }
  validates :time_zone, inclusion: { in: [Boat::TIME_ZONE] }
  validates :passengers, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 500 }
  validates :daily_rate_cents, :total_cents, numericality: { only_integer: true, greater_than: 0 }
  validate do
    errors.add(:ends_on, "debe ser posterior al inicio") if starts_on && ends_on && ends_on <= starts_on
    errors.add(:total_cents, "no coincide con la tarifa y duración") if starts_on && ends_on && total_cents != days * daily_rate_cents.to_i
    errors.add(:cancelled_at, "no coincide con el estado") if (status == "cancelled") != cancelled_at.present?
  end
  scope :confirmed, -> { where(status: "confirmed") }
  scope :overlapping, ->(first, last) { where("starts_on < ? AND ends_on > ?", last, first) }

  def days = (ends_on - starts_on).to_i
  def cancellation_deadline = starts_on.in_time_zone(time_zone) - 24.hours
  def cancellable? = status == "confirmed" && Time.current <= cancellation_deadline

  def details(owner_view: false)
    result = attributes.slice("id", "starts_on", "ends_on", "passengers", "status", "daily_rate_cents", "total_cents", "currency", "time_zone", "cancelled_at").merge(
      "boat" => boat.attributes.slice("id", "name", "port", "active"), "days" => days,
      "cancellation_deadline" => cancellation_deadline.utc.iso8601, "can_cancel" => cancellable?
    )
    result["customer"] = { name: user.name } if owner_view
    result
  end
end
