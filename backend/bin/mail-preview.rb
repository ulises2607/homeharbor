#!/usr/bin/env ruby
# Render a development-only file delivery as UTF-8 HTML, without sending mail.
require "bundler/setup"
require "mail"
require "pathname"
require_relative "../lib/development_mail_preview"

abort "Only development mail previews are supported" if ENV.fetch("RAILS_ENV", "development") != "development"
recipient = ARGV.fetch(0) { abort "Usage: ruby bin/mail-preview.rb demo@example.test" }
abort "Invalid recipient filename" unless recipient.match?(/\A[a-zA-Z0-9._+\-]+@[a-zA-Z0-9.\-]+\z/)
directory = Pathname.new(__dir__).join("../tmp/mails").expand_path
source = directory.join(recipient)
abort "No local message found for this recipient" unless source.file?
target = directory.join("#{recipient}.html")
target.binwrite(DevelopmentMailPreview.latest_html(source.binread))
puts target
