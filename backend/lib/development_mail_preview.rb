require "mail"

module DevelopmentMailPreview
  def self.latest_html(contents)
    # Mail::FileDelivery appends multiple messages to the recipient's file.
    normalized = contents.gsub(/\r+\n/, "\r\n")
    latest = normalized.split(/\r\n\r\n(?=Date: [^\r\n]+\r\nFrom:)/).last
    mail = Mail.read_from_string(latest)
    (mail.html_part || mail).body.decoded
  end
end
