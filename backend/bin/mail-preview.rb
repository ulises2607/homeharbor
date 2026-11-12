#!/usr/bin/env ruby
# Render a development-only file delivery as UTF-8 HTML, without sending mail.
require "bundler/setup"
require "mail"
require "pathname"

abort "Only development mail previews are supported" if ENV.fetch("RAILS_ENV", "development") != "development"
recipient = ARGV.fetch(0) { abort "Usage: ruby bin/mail-preview.rb demo@example.test" }
abort "Invalid recipient filename" unless recipient.match?(/\A[a-zA-Z0-9._+\-]+@[a-zA-Z0-9.\-]+\z/)
directory = Pathname.new(__dir__).join("../tmp/mails").expand_path
source = directory.join(recipient)
abort "No local message found for this recipient" unless source.file?
# Mail's file delivery can duplicate carriage returns in Windows text mode.
mail = Mail.read_from_string(source.binread.gsub(/\r+\n/, "\r\n"))
part = mail.html_part || mail
target = directory.join("#{recipient}.html")
target.binwrite(part.body.decoded)
puts target
