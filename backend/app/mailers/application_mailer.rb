class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV.fetch("MAILER_FROM", "Homeharbor <no-reply@homeharbor.test>") }
  layout "mailer"
end
