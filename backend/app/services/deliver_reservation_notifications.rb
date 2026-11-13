class DeliverReservationNotifications
  MAX_ATTEMPTS = 5

  def self.call(limit: 50)
    processed = 0
    limit.times do
      found = ReservationNotification.transaction do
        notification = ReservationNotification.pending.order(:id).lock("FOR UPDATE SKIP LOCKED").first
        next false unless notification
        begin
          ReservationMailer.with(notification: notification).notice.deliver_now
          notification.update!(delivered_at: Time.current, attempts: notification.attempts + 1, last_error: nil)
        rescue StandardError => error
          attempts = notification.attempts + 1
          notification.update!(attempts: attempts, last_error: error.class.name,
            available_at: Time.current + [2**attempts, 60].min.minutes,
            failed_at: attempts >= MAX_ATTEMPTS ? Time.current : nil)
          # Do not log message bodies, recipient addresses, SMTP responses or credentials.
          Rails.logger.warn("reservation_notification_failed id=#{notification.id} error=#{error.class.name}")
        end
        true
      end
      break unless found
      processed += 1
    end
    processed
  end
end
