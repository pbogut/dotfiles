#!/usr/bin/env ruby
#=================================================
# name:   mutt-add-tracking-pixel.rb
# author: Pawel Bogut <https://pbogut.me>
# date:   12/12/2020
#=================================================

require 'mail'
require 'base64'

require File.dirname(__FILE__) + '/config'

payload = $stdin.read
begin
  mail = Mail.new(payload)
rescue
  mail = Mail.new(payload.encode!('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: ''))
end

new_mail = Mail.new
new_mail.header = mail.header.to_s

def add_tracking_to_part(part, link)
    part.body = part.body.to_s.gsub('</body>', "#{link}\n</body>")
end

message_id = mail.header['Message-ID'].to_s
encoded_id = Base64.encode64(message_id).chop.gsub('=', '')
tracking_base_url = MyConfig.get("email/open_tracking/api_url")
tracking_url = "#{tracking_base_url}/image/#{encoded_id}.gif"
tracking_pixel = "<img alt=\"Open pixel\" style=\"border: 0px; width: 0px; max-width: 1px;\" src=\"#{tracking_url}\" />"

mail.parts.each do |part|
  if part.content_type =~ %r{^multipart/alternative}
    add_tracking_to_part(part.html_part, tracking_pixel)
  end
  if part.content_type =~ %r{^text/html}
    add_tracking_to_part(part, tracking_pixel)
  end
end

puts mail.to_s
