require "test_helper"
require_relative "../../lib/development_mail_preview"

class DevelopmentMailPreviewTest < ActiveSupport::TestCase
  test "preview selects the latest appended message including Windows line endings" do
    messages = ["Confirmar cuenta", "Reserva cancelada · USD"].map do |title|
      Mail.new do
        from "no-reply@example.test"
        to "guest@example.test"
        subject title
        text_part { body title }
        html_part do
          content_type "text/html; charset=UTF-8"
          body "<h1>#{title}</h1>"
        end
      end.encoded
    end
    appended = messages.join("\r\n\r\n").gsub("\r\n", "\r\r\n")
    html = DevelopmentMailPreview.latest_html(appended)
    assert_includes html, "Reserva cancelada"
    assert_not_includes html, "Confirmar cuenta"
    assert_not_includes html, "Content-Type:"
    assert_includes DevelopmentMailPreview.latest_html(messages.first), "Confirmar cuenta"
  end
end
