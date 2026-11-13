namespace :notifications do
  desc "Deliver up to 50 due reservation notices, with persisted retries"
  task deliver: :environment do
    puts "Processed #{DeliverReservationNotifications.call} reservation notices."
  end

  desc "Run the reservation notification worker; stop with Ctrl+C"
  task work: :environment do
    interval = Integer(ENV.fetch("NOTIFICATION_POLL_SECONDS", "10"))
    abort "NOTIFICATION_POLL_SECONDS must be between 1 and 300" unless interval.between?(1, 300)
    loop do
      Rails.application.executor.wrap { DeliverReservationNotifications.call }
      sleep interval
    end
  end

  desc "Show counts only; no recipient data"
  task status: :environment do
    puts({ due: ReservationNotification.pending.count,
      failed: ReservationNotification.where.not(failed_at: nil).count,
      delivered: ReservationNotification.where.not(delivered_at: nil).count }.to_json)
  end

  desc "Retry one failed notice after correcting the delivery configuration: ID=..."
  task retry: :environment do
    notice = ReservationNotification.find(Integer(ENV.fetch("ID")))
    notice.with_lock do
      abort "Only failed notices can be retried" unless notice.failed_at && !notice.delivered_at
      notice.update!(failed_at: nil, attempts: 0, available_at: Time.current, last_error: nil)
    end
    puts "Notice #{notice.id} queued again."
  end
end
