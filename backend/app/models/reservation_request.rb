require "digest"

# Parse once, before Rails' date/integer type coercion can accept partial input.
class ReservationRequest
  include ActiveModel::Model
  attr_reader :starts_on, :ends_on, :passengers, :boat_id, :expected_total_cents, :expected_currency

  def initialize(attributes, booking: false)
    values = attributes.to_h.symbolize_keys
    @booking = booking
    @starts_on = strict_date(values[:starts_on])
    @ends_on = strict_date(values[:ends_on])
    @passengers = integer(values[:passengers])
    @boat_id = integer(values[:boat_id])
    @expected_total_cents = integer(values[:expected_total_cents])
    @expected_currency = values[:expected_currency]
  end

  validate do
    errors.add(:starts_on, "usá una fecha válida YYYY-MM-DD") unless starts_on
    errors.add(:ends_on, "usá una fecha válida YYYY-MM-DD") unless ends_on
    errors.add(:ends_on, "debe ser posterior al primer día") if starts_on && ends_on && ends_on <= starts_on
    errors.add(:passengers, "debe ser un entero entre 1 y 500") unless passengers&.between?(1, 500)
    if @booking
      errors.add(:boat_id, "debe identificar un bote") unless boat_id&.between?(1, 9_223_372_036_854_775_807)
      errors.add(:expected_total_cents, "consultá el precio antes de reservar") unless expected_total_cents&.between?(1, 9_007_199_254_740_991)
      errors.add(:expected_currency, "indicá la moneda de la cotización") unless expected_currency.is_a?(String) && expected_currency.match?(/\A[A-Z]{3}\z/)
    end
  end

  def validate_for_boat!(boat)
    validate!
    errors.add(:starts_on, "debe ser posterior al día actual en UTC−3") if starts_on <= Time.current.in_time_zone(Boat::TIME_ZONE).to_date
    errors.add(:passengers, "supera la capacidad del bote") if passengers > boat.capacity
    raise ActiveModel::ValidationError, self if errors.any?
  end

  def quote(boat)
    days = (ends_on - starts_on).to_i
    { days: days, daily_rate_cents: boat.daily_rate_cents, total_cents: days * boat.daily_rate_cents,
      currency: boat.currency, time_zone: boat.time_zone }
  end

  def fingerprint
    Digest::SHA256.hexdigest([boat_id, starts_on.iso8601, ends_on.iso8601, passengers, expected_total_cents, expected_currency].to_json)
  end

  private

  def integer(value)
    return unless value.is_a?(Integer) || value.is_a?(String)
    Integer(value.to_s, 10, exception: false)
  end

  def strict_date(value)
    return unless value.is_a?(String) && value.match?(/\A\d{4}-\d{2}-\d{2}\z/)
    Date.iso8601(value) if value[0, 4].to_i.positive?
  rescue Date::Error
    nil
  end
end
