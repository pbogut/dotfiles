#!/usr/bin/env ruby
#=================================================
# name:   qb-lastpass.rb
# author: Pawel Bogut <pbogut@ukpos.com> <http://pbogut.me>
# date:   14/02/2017
#=================================================

require "csv"
require "open3"
require "nokogiri"

action, = ARGV

if !action
  cmd = "rofi -dmenu -p 'select mode:'"
  selection, _, _ = Open3.capture3(cmd, stdin_data: [
    "--copy-user-and-pass",
    "--copy-user",
    "--copy-pass",
    "--type-user-and-pass",
    "--type-user",
    "--type-pass",
    "--remove",
    "--edit",
    "--add",
    "--show"
  ].join("\n"))
  selection, _, _ = Open3.capture3('keepass.rb ' + selection)
  exit
end


xml = `keepass-cli extract`
formated_list = ''
no = 0
doc = Nokogiri::XML(xml)
entries = doc.xpath('//Root//Group/Entry')
indexes = Hash.new
entries.each do |entry|
  no += 1
  cat = entry.xpath('../Name').text
  if cat == 'Recycle Bin'
    next
  end
  if cat == 'Root'
    cat = nil
  end
  name = entry.xpath('./String/Key[text()="Title"]/../Value').text
  url = entry.xpath('./String/Key[text()="URL"]/../Value').text
  user = entry.xpath('./String/Key[text()="UserName"]/../Value').text
  cat = "#{cat}/" if cat

  indexes[no] = name
  if name
    formated_list <<  ('%3.3s| %-50.50s %-50.50s %s' % [no, "#{cat}#{name}" , user, url]) + "\n"
  end
end

search_parts = []
# get only top part of domain
site_parts = []
url = ENV['QUTE_URL'] || ''
url.gsub(/^.*?\/\/(.*?)[\/:].*/, '\1').split('.').reverse.each do |p|
  if (p.length < 5 or !p.match(/\./)) and site_parts.reverse.join('.').length < 8
    site_parts << p
  end
  # search_parts << p
end
site_url = site_parts.reverse.join('.')
search_urls = site_parts.join(' ')

if action == "--add"
  open(ENV['TMPDIR'] + '/_lpass_url', 'w') { |f| f << url }
  _, _, _ = Open3.capture3('urxvt -e keepass-cli new "' + (site_url.empty? ? 'new-site' : site_url) + '" "' + url + '"')
  exit
end

prompt = case action
  when "--copy-user"
    "cpuser"
  when "--copy-pass"
    "cppass"
  when "--copy-user-and-pass"
    "copy"
  when "--type-user-and-pass"
    "login"
  when "--type-user"
    "user"
  when "--type-pass"
    "pass"
  when "--remove"
    "remove"
  when "--edit"
    "edit"
  when "--show"
    "show"
  else
    "acc"
end

if !action
  action = "--copy-user-and-pass"
end

cmd = "(sleep 0.2s; xdotool keyup Ctrl; xdotool type '#{search_urls} ')" +
      " & rofi -dmenu -p '#{prompt}:'"
selection, _, _ = Open3.capture3(cmd, stdin_data: formated_list)

index = selection.gsub(/(\d+).*/, '\1').to_i

exit unless index > 0

name = indexes[index]
result, _, _ = Open3.capture3("keepass-cli", "show", name)
pass = ''
user = ''
result.gsub(/^Password: (.*)$/) do |match|
  pass = match.gsub(/^Password: (.*)$/, '\1')
end
result.gsub(/^UserName: (.*)$/) do |match|
  user = match.gsub(/^UserName: (.*)$/, '\1')
end

sleep 0.2

if action == '--copy-user'
  _, _, _ = Open3.capture3('xsel -b -i', stdin_data: user)
end
if action == '--copy-pass'
  _, _, _ = Open3.capture3('xsel -p -i', stdin_data: pass)
end
if action == '--copy-user-and-pass'
  _, _, _ = Open3.capture3('xsel -b -i', stdin_data: user)
  _, _, _ = Open3.capture3('xsel -p -i', stdin_data: pass)
end
if action == '--type-user'
  File.open(ENV['QUTE_FIFO'], 'w') do |file|
    file.write("fake-key #{user}\n")
    # file.write("fake-key -g <esc>i\n")
  end
end
if action == '--type-pass'
  File.open(ENV['QUTE_FIFO'], 'w') do |file|
    file.write("fake-key #{pass}\n")
    # file.write("fake-key -g <esc>i\n")
  end
end
if action == '--type-user-and-pass' or action.empty?
  File.open(ENV['QUTE_FIFO'], 'w') do |file|
    file.write("fake-key #{user}\n")
    file.write("fake-key <tab>\n")
    file.write("fake-key #{pass}\n")
    # file.write("fake-key -g <esc>i\n")
  end
end
if action == "--edit"
  puts "keepass-cli change '#{name}'"
  out, _, _ = Open3.capture3("urxvt -e keepass-cli change '#{name}'")
  puts out
end
if action == "--remove"
  puts "keepass-cli rm '#{name}'"
  out, _, _ = Open3.capture3("keepass-cli rm '#{name}'")
  puts out
end
if action == "--show"
  puts "keepass-cli show '#{name}'"
  out, _, _ = Open3.capture3("keepass-cli show '#{name}'")

  i = 0
  lines = []
  out.split("\n").each do |line|
    lines << line
    if line.match(/Password: .*/)
      pass = line.gsub(/Password: (.*)/, '\1')
      numbers = ""
      passwds = ""
      pass.split("").each do |c|
        i = i + 1
        numbers << "#{i}\t"
        passwds << "#{c}\t"
      end
      lines << numbers
      lines << passwds
    end
  end
  width = 100 + (i * 20)
  out, _, _ = Open3.capture3("zenity --info --width=#{width} --text=\"#{lines.join("\n")}\"")
end
