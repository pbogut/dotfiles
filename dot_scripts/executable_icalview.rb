#!/bin/ruby
#=================================================
# name:   icalview.rb
# author: Pawel Bogut <http://pbogut.me>
# date:   05/01/2017
#=================================================

file = File.open(ARGV[0], 'rb')
ical = file.read

ical.gsub!(/\r\n /, '')
ical.gsub!(/\n /, '')

summary = ''
dtstart = ''
dtend = ''
description = ''

skip = true
ical.split("\n").each do |line|
  if line.match "BEGIN"
    skip = true
  end
  if line.match "BEGIN:VEVENT"
    skip = false
  end
  next if skip

  if line.match(/^SUMMARY.*:/)
    summary = line.match(/^SUMMARY.*:(.*)/)[1]
  end
  if line.match(/^DESCRIPTION.*:/)
    description = line.match(/^DESCRIPTION.*:(.*)/)[1]
      .gsub(/\\n/,"\n")
      .gsub(/\\,/, ',')
  end
  if line.match(/^DTSTART.*:/)
    parts = line.match(/^DTSTART.*:(.*)/)[1]
      .match(/(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})/)
    dtstart = "#{parts[3]}/#{parts[2]}/#{parts[1]} #{parts[4]}:#{parts[5]}:#{parts[6]}"
  end
  if line.match(/^DTEND.*:/)
    parts = line.match(/^DTEND.*:(.*)/)[1]
      .match(/(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})/)
    dtend = "#{parts[3]}/#{parts[2]}/#{parts[1]} #{parts[4]}:#{parts[5]}:#{parts[6]}"
  end
end


puts "Title: #{summary}"
puts "Date: #{dtstart} - #{dtend}"
puts ""
puts description
