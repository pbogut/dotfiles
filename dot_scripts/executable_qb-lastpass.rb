#!/usr/bin/env ruby
#=================================================
# name:   qb-lastpass.rb
# author: Pawel Bogut <pbogut@ukpos.com> <http://pbogut.me>
# date:   14/02/2017
#=================================================

require "csv"
require "open3"

action, = ARGV

list = `lpass export`
formated_list = ''
no = -1
list.each_line do |line|
  no += 1
  next if no <= 0
  begin
    line = CSV.parse(line)[0]
    url = line[0]
    user = line[1]
    # pass= line[2]
    name = line[4]
    cat = line[5]
    cat = "#{cat}/" if cat
    formated_list <<  ('%3.3s| %-50.50s %-50.50s %s' % [no, "#{cat}#{name}" , user, url]) + "\n"
  rescue
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
  _, _, _ = Open3.capture3('urxvt -e lpass add ' + (site_url.empty? ? 'new-site' : site_url))
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

result_line = list.split("\n")[index]
result = CSV.parse(result_line)[0]

user = result[1]
pass = result[2]
cat = result[5]
name = result[4]

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
if action == "--remove"
  fullname = [cat, name].join("/").gsub(/^\//, "")
  out, _, _ = Open3.capture3("lpass rm '#{fullname}'")
  puts out
end
