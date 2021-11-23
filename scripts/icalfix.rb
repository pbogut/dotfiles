#!/bin/ruby
#=================================================
# name:   icalfix.rb
# author: Pawel Bogut <http://pbogut.me>
# date:   11/11/2021
#=================================================
require 'securerandom'
require 'open3'

file = File.open(ARGV[0], 'rb')
ical = file.read

unless ical.match('UID')
  parts = []
  ical.split("\n").each do |line|
    parts << line

    if line.match 'BEGIN:VEVENT'
      uuid = SecureRandom.uuid
      parts << "UID:#{uuid}@icalimport.rb"
    end
  end
  file.close
  File.open(ARGV[0], 'w') do |f|
    parts.each do |line|
      f << "#{line}\n"
    end
  end
end
