#!/usr/bin/env ruby

require 'mail'

payload = $stdin.read
begin
  mail = Mail.new(payload)
rescue
  mail = Mail.new(payload.encode!('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: ''))
end

if mail.parts.map(&:filename).include?("html-markdown-alternative.html")
  new_mail = Mail.new
  new_mail.header = mail.header.to_s

  text = nil
  html = nil
  new_parts = []

  mail.parts.each do |part|
    if part.content_type =~ %r{^text/plain}
      text = part
    elsif part.filename == 'html-markdown-alternative.html'
      html = part
    elsif !part.filename.nil? && part.filename != ''
      new_parts << part
    end
  end

  bodypart = Mail::Part.new
  # remove attachment file information, otherwise gmail is
  # displaying attachmet list instead of html in the email body
  text.content_disposition = nil
  text.content_type = "text/plain; charset=UTF-8"
  html.content_disposition = nil
  html.content_type = "text/html; charset=UTF-8"

  bodypart.text_part = text
  bodypart.html_part = html
  new_mail.add_part bodypart

  new_parts.each do |part|
    new_mail.attachments[part.filename] = part.decoded
  end
else
  new_mail = mail
end

puts new_mail.to_s
