Devise.setup do |config|
  require "devise/orm/active_record"
  config.mailer_sender = ENV.fetch("MAILER_FROM", "Homeharbor <no-reply@homeharbor.example>")
  config.mailer = "AccountMailer"
  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]
  config.skip_session_storage = [:http_auth]
  config.stretches = Rails.env.test? ? 1 : 12
  config.paranoid = true
  config.password_length = 12..128
  config.reconfirmable = true
  config.confirm_within = 3.days
  config.reset_password_within = 6.hours
  config.lock_strategy = :failed_attempts
  config.maximum_attempts = 5
  config.unlock_strategy = :time
  config.unlock_in = 30.minutes
  config.navigational_formats = []
end
