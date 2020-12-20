#!/usr/bin/env ruby
#=================================================
# name:   mutt-put-on-imap.rb
# author: Pawel Bogut <https://pbogut.me>
# date:   12/12/2020
#=================================================

require 'date'
require 'mail'
require 'net/imap'

require File.dirname(__FILE__) + '/config'

payload = $stdin.read
begin
  mail = Mail.new(payload)
rescue
  mail = Mail.new(payload.encode!('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: ''))
end

message_id = mail.header['Message-ID']
email = mail.from.first
server = email.split('@')[1]

user = MyConfig.get("email/#{email}/user", email)
pass = MyConfig.get("email/#{email}/pass")
imap_url = MyConfig.get("email/#{server}/imap/host")
imap_port = MyConfig.get("email/#{server}/imap/port", 993)
imap_ssl = MyConfig.get("email/#{server}/imap/ssl", true)

if user.nil? or pass.nil? or imap_url.nil?
  puts "Missing data for #{server} server"
  exit 1
end

imap = Net::IMAP.new(imap_url, imap_port, imap_ssl)
imap.login(user, pass)

imap.select('INBOX')
# in case we run it twice or email already exists (bbc etc)
# just remove previous ones with that id
imap.uid_search(['HEADER', 'Message-ID', message_id.to_s]).each do |message_uid|
  imap.uid_store(message_uid, '+FLAGS', [:Deleted])
end

res = imap.append('INBOX', payload, [:Seen], mail.date.to_time)

imap.expunge
imap.disconnect

puts payload
