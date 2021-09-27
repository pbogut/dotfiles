#!/usr/bin/env ruby
#=================================================
# name:   qb-lastpass.rb
# author: Pawel Bogut <pbogut@ukpos.com> <http://pbogut.me>
# date:   14/02/2017
#=================================================

require "csv"
require "open3"
require "nokogiri"
require "clipboard"
require "rotp"
require "uri"
require 'cgi'

def has_otp(notes)
  notes.split("\n").each do |line|
    if line.match(/^otpauth:\/\//)
      return true
    end
  end
  return false
end

def get_otp(notes)
  uri = nil
  notes.split("\n").each do |line|
    if line.match(/^otpauth:\/\//)
      uri = URI.parse(line.gsub(" ", "%20"))
      break
    end
  end


  secret = CGI::parse(uri.query)['secret']
  if uri.host == 'totp'
    totp = ROTP::TOTP.new(secret[0])
    return totp.now()
  else
    raise "#{uri.host} not implemented"
  end
end

action, = ARGV

if !action
  cmd = "rofi -dmenu -i -p 'select mode:'"
  selection, _, _ = Open3.capture3(cmd, stdin_data: [
    "--copy-user-and-pass",
    "--copy-user",
    "--copy-pass",
    "--type-user-and-pass",
    "--type-user",
    "--type-pass",
    "--type-otpauth",
    "--remove",
    "--edit",
    "--add",
    "--show",
  ].join("\n"))
  selection = "--exit" if selection == ""
  selection, _, _ = Open3.capture3('keepass.rb ' + selection)
  exit
end


xml = `keepass-cli export`
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
  notes = entry.xpath('./String/Key[text()="Notes"]/../Value').text
  otp = " 2FA" if has_otp(notes)
  cat = "#{cat}/" if cat

  indexes[no] = name
  if name
    formated_list <<  ('%3.3s| %-50.50s %-50.50s %-8.8s %s' % [no, "#{cat}#{name}" , user, otp, url]) + "\n"
  end
end

# get only top part of domain
site_parts = []
url = ENV['QUTE_URL'] || ''
url.gsub(/^.*?\/\/(.*?)[\/:].*/, '\1').split('.').reverse.each do |p|
  # if (p.length < 5 or !p.match(/\./)) and site_parts.reverse.join('.').length < 8
  #   site_parts << p
  # end
  should_add = true
  [
    /^www/,
    /^local/,
    /^login/,
    /^dev/,
    /^staging/,
    /^online/,
    /^system/,
    /^app/,
    /^dash/,
    /^panel/,
    /^dashboard/,
  ].each do |pattern|
    if (p.match(pattern))
      should_add = false
    end
  end
  if (should_add)
     site_parts << p
  end
end
site_url = site_parts.reverse.join('.')
site_base_url = url.gsub(/^(.*?\/\/.*?[\/:].*?\/?)+.*/, '\1')
search_urls = site_parts.join(' ')
if action == "--type-otpauth"
  search_urls = ' ' + search_urls
end
user_name = site_url.gsub(/\...\...$/, '').gsub(/\...$/, '').gsub(/\....$/, '').gsub(/[^a-z0-9]/, '_')

if action == "--add"
  open(ENV['TMPDIR'] + '/_lpass_url', 'w') { |f| f << url }
  _, _, _ = Open3.capture3('urxvt', '-e', 'keepass-cli', 'new', (site_url.empty? ? 'new-site' : site_url), site_base_url, user_name)
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
  when "--type-otpauth"
    "otpauth"
  when "--remove"
    "remove"
  when "--edit"
    "edit"
  when "--show"
    "show"
  else
    exit
end

if !action
  action = "--copy-user-and-pass"
end

cmd = "rofi -filter '#{search_urls} ' -dmenu -i -p '#{prompt}:'"
selection, _, _ = Open3.capture3(cmd, stdin_data: formated_list)
selection = selection.force_encoding('utf-8').encode

index = selection.gsub(/(\d+).*/, '\1').to_i

exit unless index > 0

name = indexes[index]
result, _, _ = Open3.capture3("keepass-cli", "show", "-s", name)
# Open3.capture3('copyq', 'disable') # disable copyq from storing password
# Open3.capture3('keepass-cli', 'clip', name)
# Open3.capture3('copyq', 'enable') # allow copyq keep working after password was coppied
# pass = Clipboard.paste
pass = ''
user = ''
otpauth = ''
result.gsub(/^UserName: (.*)$/) do |match|
  user = match.gsub(/^UserName: (.*)$/, '\1')
end
result.gsub(/^Password: (.*)$/) do |match|
  pass = match.gsub(/^Password: (.*)$/, '\1')
end
result.gsub(/^(Notes: )?otpauth:\/\/(.*)$/) do |match|
  otpurl = match.gsub(/^(Notes: )?(otpauth:\/\/.*)$/, '\2')
  otpauth = get_otp(otpurl)
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
  if ENV['QUTE_FIFO']
    File.open(ENV['QUTE_FIFO'], 'w') do |file|
      file.write("fake-key #{user}\n")
      # file.write("fake-key -g <esc>i\n")
    end
  else
    cmd = "sleep 0.5s; xdotool type --clearmodifiers '#{user}'"
    Open3.capture3(cmd)
  end
end
if action == '--type-pass'
  if ENV['QUTE_FIFO']
    File.open(ENV['QUTE_FIFO'], 'w') do |file|
      file.write("fake-key #{pass}\n")
      # file.write("fake-key -g <esc>i\n")
    end
  else
    Open3.capture3('sleep', '0.5s')
    Open3.capture3('xdotool', 'type', '--clearmodifiers', pass)
  end
end
if action == '--type-user-and-pass' or action.empty?
  if ENV['QUTE_FIFO']
    File.open(ENV['QUTE_FIFO'], 'w') do |file|
      file.write("fake-key #{user}\n")
      file.write("fake-key <tab>\n")
      file.write("fake-key #{pass}\n")
      # file.write("fake-key -g <esc>i\n")
    end
  else
    Open3.capture3('sleep', '0.5s')
    Open3.capture3('xdotool', 'type', '--clearmodifiers', user)
    Open3.capture3('xdotool', 'type', '--clearmodifiers', "\t")
    Open3.capture3('xdotool', 'type', '--clearmodifiers', pass)
  end
end
if action == '--type-otpauth'
  if ENV['QUTE_FIFO']
    File.open(ENV['QUTE_FIFO'], 'w') do |file|
      file.write("fake-key #{otpauth}\n")
    end
  else
    cmd = "sleep 0.5s; xdotool type --clearmodifiers '#{otpauth}'"
    Open3.capture3(cmd)
  end
end
if action == "--edit"
  puts "keepass-cli change '#{name}'"
  out, _, _ = Open3.capture3('urxvt', '-e', 'keepass-cli', 'change', name)
  puts out
end
if action == "--remove"
  puts "keepass-cli rm '#{name}'"
  out, _, _ = Open3.capture3('keepass-cli', 'rm', name)
  puts out
end
if action == "--show"
  puts "keepass-cli show '#{name}'"
  out, _, _ = Open3.capture3('keepass-cli', 'show', name)

  i = 0
  lines = []
  out.split("\n").each do |line|
    if line.match(/Password: .*/)
      numbers = ""
      passwds = ""
      pass.split("").each do |c|
        i = i + 1
        numbers << "#{i}\t"
        passwds << "#{c}\t"
      end
      lines << "Password:"
      lines << numbers
      lines << passwds
    else
      lines << line
    end
  end
  width = 100 + (i * 20)
  out, _, _ = Open3.capture3("zenity --info --width=#{width} --text=\"#{lines.join("\n")}\"")
end
