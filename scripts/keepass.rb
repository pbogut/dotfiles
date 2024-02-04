#!/usr/bin/env ruby
#=================================================
# name:   qb-lastpass.rb
# author: Pawel Bogut <pbogut@ukpos.com> <http://pbogut.me>
# date:   14/02/2017
#=================================================

require 'open3'
require 'nokogiri'
require 'clipboard'
require 'rotp'
require 'uri'
require 'csv'
require 'cgi'

# rubocop:disable Metrics/AbcSize,Metrics/MethodLength
def get_otp(url)
  uri = URI.parse(url.gsub(' ', '%20'))
  return nil if uri.nil?

  params = CGI.parse(uri.query)
  secret = params['secret'][0]
  digits = params['digits'][0]
  digits = digits ? digits.to_i : 6

  if uri.host == 'totp'
    totp = ROTP::TOTP.new(secret, digits: digits)
    totp.now
  elsif uri.host == 'steam'
    # print(uri.host)
    steam_user = uri.path.gsub(/^.*:/, '')
    code, = Open3.capture3("steamctl authenticator code #{steam_user}")
    code.strip
  else
    raise "#{uri.host} not implemented"
  end
end
# rubocop:enable Metrics/AbcSize,Metrics/MethodLength

def rofi(prompt, search, data)
  Open3.capture3('rofi', '-dmenu', '-i', '-p', "#{prompt}:", '-filter', search, stdin_data: data)
end

# rubocop:disable Metrics/MethodLength
def wofi(prompt, search, data)
  Open3.capture3(
    'wofi',
    '--cache-file',
    '/dev/null',
    '--dmenu',
    '-M',
    'multi-contains',
    '-i',
    '-p',
    "#{prompt}:",
    '--search',
    search,
    stdin_data: data
  )
end
# rubocop:enable Metrics/MethodLength

def dmenu(prompt, search, data)
  if ENV['WAYLAND_DISPLAY']
    wofi(prompt, search, data || '')
  else
    rofi(prompt, search, data || '')
  end
end

def to_clipboard(text, primary: false)
  if ENV['WAYLAND_DISPLAY']
    type = primary ? '-p' : '-b'
    Open3.capture3("xsel #{type} -i", stdin_data: text)
  else
    type = primary ? '-p' : ''
    Open3.capture3('wl-copy', type, text)
  end
end

def type(text)
  if ENV['WAYLAND_DISPLAY']
    Open3.capture3('wtype', '-m', 'ctrl', '-m', 'shift', '-m', 'alt', '--', text)
  else
    Open3.capture3('xdotool', 'type', '--clearmodifiers', text)
  end
end

# rubocop:disable Metrics/MethodLength
def get_site_parts(url)
  site_parts = []
  url.gsub(%r{^.*?//(.*?)[/:].*}, '\1').split('.').reverse.each do |p|
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
      /^dashboard/
    ].each do |pattern|
      should_add = false if p.match(pattern)
    end
    site_parts << p if should_add
  end
  site_parts
end
# rubocop:enable Metrics/MethodLength

action, = ARGV

unless action
  selection, = dmenu('select mode', '', [
    '--login',
    '--copy-user-and-pass',
    '--copy-user',
    '--copy-pass',
    '--type-user-and-pass',
    '--type-user',
    '--type-pass',
    '--type-otpauth',
    '--remove',
    '--edit',
    '--add',
    '--show'
  ].join("\n"))
  selection = '--exit' if selection == ''
  Open3.capture3("keepass.rb #{selection}")
  exit
end

xml = `keepass-cli export`
formated_list = ''
no = 0
doc = Nokogiri::XML(xml)
entries = doc.xpath('//Root//Group/Entry')
indexes = {}
entries.each do |entry|
  no += 1
  cat = entry.xpath('../Name').text
  next if cat == 'Recycle Bin'

  cat = nil if cat == 'Root'
  name = entry.xpath('./String/Key[text()="Title"]/../Value').text
  url = entry.xpath('./String/Key[text()="URL"]/../Value').text
  user = entry.xpath('./String/Key[text()="UserName"]/../Value').text
  otpauth = entry.xpath('./String/Key[text()="otpauth"]/../Value').text
  notes = entry.xpath('./String/Key[text()="Notes"]/../Value').text
  otp = ' 2FA' if otpauth.length.positive?
  cat = "#{cat}/" if cat

  indexes[no] = entry
  next unless name

  # rubocop:disable Style/FormatStringToken,Style/FormatString
  formated_list << ("%3.3s| %-50.50s %-50.50s %-8.8s %-100.100s %s %s %s\n" % [
    no,
    "#{cat}#{name}",
    user,
    otp,
    url,
    get_site_parts(url).join(' '),
    url.split(%r{[\s/.]}).reverse.join(' '),
    notes.split("\n").each { |line| line.split('.').reverse.join(' ') }.join(';')
  ])
  # rubocop:enable Style/FormatStringToken,Style/FormatString
end

url = ENV['QUTE_URL'] || ''
# get only top part of domain
site_parts = get_site_parts(url)
site_url = site_parts.reverse.join('.')
site_base_url = url.gsub(%r{^(.*?//.*?[/:].*?/?)+.*}, '\1')
search_urls = site_parts.join(' ')
search_urls = " #{search_urls}" if action == '--type-otpauth'
user_name = site_url.gsub(/\...\...$/, '').gsub(/\...$/, '').gsub(/\....$/, '').gsub(/[^a-z0-9]/, '_')

if action == '--add'
  site_url = (site_url.empty? ? 'new-site' : site_url)
  Open3.capture3(ENV['TERMINAL'], '-e', 'keepass-cli', 'new', site_url, site_base_url, user_name)
  exit
end

prompt = case action
         when '--copy-user'
           'cpuser'
         when '--copy-pass'
           'cppass'
         when '--copy-user-and-pass'
           'copy'
         when '--type-user-and-pass'
           'login'
         when '--login'
           'login'
         when '--type-user'
           'user'
         when '--type-pass'
           'pass'
         when '--type-otpauth'
           'otpauth'
         when '--remove'
           'remove'
         when '--edit'
           'edit'
         when '--show'
           'show'
         else
           exit
         end

action ||= '--copy-user-and-pass'
selection, = dmenu(prompt, search_urls, formated_list)
selection = selection.force_encoding('utf-8').encode

index = selection.gsub(/(\d+).*/, '\1').to_i

exit unless index.positive?

entry = indexes[index]

name = entry.xpath('./String/Key[text()="Title"]/../Value').text
user = entry.xpath('./String/Key[text()="UserName"]/../Value').text
pass = entry.xpath('./String/Key[text()="Password"]/../Value').text
otpurl = entry.xpath('./String/Key[text()="otpauth"]/../Value').text
otpauth = get_otp(otpurl) unless otpurl.empty?
autologin = entry.xpath('./String/Key[text()="autologin"]/../Value').text

unless autologin.empty?
  autologin.gsub!('{USER}', user)
  autologin.gsub!('{PASS}', pass)
end

sleep 0.2

to_clipboard(user) if action == '--copy-user'
to_clipboard(pass, primary: true) if action == '--copy-pass'
if action == '--copy-user-and-pass'
  to_clipboard(user) if action == '--copy-user'
  to_clipboard(pass, primary: true) if action == '--copy-pass'
end
if action == '--type-user'
  if ENV['QUTE_FIFO']
    File.open(ENV['QUTE_FIFO'], 'w') do |file|
      file.write("fake-key #{user}\n")
    end
  else
    Open3.capture3('sleep', '0.5s')
    type(user)
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
    type(pass)
  end
end
if action == '--login'
  if ENV['QUTE_FIFO']
    File.open(ENV['QUTE_FIFO'], 'w') do |file|
      if !autologin.empty?
        parts = autologin.split("\n").join("\n<tab>\n").split("\n")
        parts.each do |part|
          file.write("fake-key #{part}\n")
          # file.write("fake-key <tab>\n")
        end
      else
        file.write("fake-key #{user}\n")
        file.write("fake-key <tab>\n")
        file.write("fake-key #{pass}\n")
      end
    end
  else
    Open3.capture3('sleep', '0.5s')
    if !autologin.empty?
      parts = autologin.split("\n").join("\n\t\n").split("\n")
      parts.each do |part|
        type(part)
        Open3.capture3('sleep', '0.1s')
      end
    else
      type(user)
      type("\t")
      type(pass)
    end
  end
end
if action == '--type-user-and-pass' || action.empty?
  if ENV['QUTE_FIFO']
    File.open(ENV['QUTE_FIFO'], 'w') do |file|
      file.write("fake-key #{user}\n")
      file.write("fake-key <tab>\n")
      file.write("fake-key #{pass}\n")
    end
  else
    Open3.capture3('sleep', '0.5s')
    type(user)
    type("\t")
    type(pass)
  end
end
if action == '--type-otpauth'
  if ENV['QUTE_FIFO']
    File.open(ENV['QUTE_FIFO'], 'w') do |file|
      file.write("fake-key #{otpauth}\n")
    end
  else
    Open3.capture3('sleep', '0.5s')
    type(otpauth)
  end
end
if action == '--edit'
  puts "keepass-cli change '#{name}'"
  out, = Open3.capture3('urxvt', '-e', 'keepass-cli', 'change', name)
  puts out
end
if action == '--remove'
  puts "keepass-cli rm '#{name}'"
  out, = Open3.capture3('keepass-cli', 'rm', name)
  puts out
end
if action == '--show'
  puts "keepass-cli show '#{name}'"
  out, = Open3.capture3('keepass-cli', 'show', name)

  i = 0
  lines = []
  out.split("\n").each do |line|
    if line.match(/Password: .*/)
      numbers = ''
      passwds = ''
      pass.split('').each do |c|
        i += 1
        numbers << "#{i}\t"
        passwds << "#{c}\t"
      end
      lines << 'Password:'
      lines << numbers
      lines << passwds
    else
      lines << line
    end
  end
  width = 100 + (i * 20)
  Open3.capture3("yad --title=\"keepass show\" --info --width=#{width} --text=\"#{lines.join("\n")}\"")
end
