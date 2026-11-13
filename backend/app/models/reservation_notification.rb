class ReservationNotification < ApplicationRecord
  belongs_to :reservation
  validates :event, inclusion: { in: %w[confirmed cancelled] }
  validates :audience, inclusion: { in: %w[customer owner] }
  scope :pending, -> { where(delivered_at: nil, failed_at: nil).where("available_at <= ?", Time.current) }

  # Called inside the booking/cancellation transaction: intent survives process restarts.
  def self.record!(reservation, event:)
    %w[customer owner].each do |audience|
      create!(reservation: reservation, event: event, audience: audience, available_at: Time.current)
    end
  end
end
