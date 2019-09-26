#!/usr/bin/env ruby
#=================================================
# name:   mail-check-attachments.rb
# author: Pawel Bogut <https://pbogut.me>
# date:   24/01/2019
#=================================================

require 'mail'
require "readline"

payload = $stdin.read

begin
  mail = Mail.new(payload)
rescue
  mail = Mail.new(payload.encode!('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: ''))
end

has_mentioned_attachment = false
has_attachment = false

if mail.parts.length > 0
  mail.parts.each do |part|
    `echo -e ">>#{part.content_type}<<\nct" | rofi -dmenu`
    if !part.filename.nil? && part.filename != ''
      `echo -e ">>#{part.filename}<<\nfileattachment\n#{has_mentioned_attachment}" | rofi -dmenu`
      has_attachment = true
    elsif part.content_type =~ %r{^text/plain} || part.content_type =~ %r{^text/html}
      has_mentioned_attachment =
        has_mentioned_attachment || part.body.to_s.encode!('utf-8', 'utf-8') =~ %r{attach|załącz|zalacz}
      `echo -e "#{part.body.to_s.encode!('utf-8', 'utf-8')}\nhtmlortext\n#{has_mentioned_attachment}" | rofi -dmenu`
    else
      `echo -e ">>#{part.content_type}#{mail.body}<<\ncosinnego\n#{part.content_type}" | rofi -dmenu`
    end
  end
else
  has_mentioned_attachment = mail.body.to_s.encode!('utf-8', 'utf-8') =~ %r{attach|załącz|zalacz}
end

if has_mentioned_attachment and not has_attachment
  `echo -e "You mentiond attachment but dont have any?" | rofi -dmenu`
end

if has_mentioned_attachment
  exit 2
end

if has_attachment
  exit 3
end

`echo -e "#{has_attachment}\n#{has_mentioned_attachment}" | rofi -dmenu`


puts "ok"
puts "ok"
puts "ok"
puts "ok"
puts "ok"
puts "ok"
puts "ok"
puts "ok"
puts "ok"
puts "ok"
puts "ok"
puts "ok"
exit 7
puts payload
