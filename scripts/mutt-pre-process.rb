#!/usr/bin/env ruby
#=================================================
# name:   mutt-pre-process.rb
# author: Pawel Bogut <https://pbogut.me>
# date:   12/12/2020
#=================================================

require 'mail'
require 'redcarpet'

payload = $stdin.read
begin
  mail = Mail.new(payload)
rescue
  mail = Mail.new(payload.encode!('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: ''))
end

@html_only = ARGV.count == 1 and ARGV[0] == "--html-only"

@tags = mail.header['X-Mutt'].to_s.split(",").map { |tag| tag.strip.to_sym }

def to_markdown(part)
  body = part.body.to_s
  # body = text.gsub(/\A.*?^$\n/m, '')
  tmp_body = body.gsub(/\r\n/,"\n") # clean up line breaks
  tmp_body = tmp_body.gsub(/^(.*)$/,'\1  ') # force line break everywhere
  new_body =  ''
  pre_block = false
  tmp_body.split("\n").each do |line|
    if line.match(/^>.*$/) && !pre_block
      new_body << "<pre class=\"quoted\">\n"
      pre_block = true
    end

    if !line.match(/^>.*$/) && pre_block
      new_body << "</pre>\n"
      pre_block = false
    end

    new_body << line + "\n"
  end
  # if body ended on quoted text, then close pre
  new_body << "</pre>\n" if pre_block

  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML,
                                     autolink: true, tables: true,
                                     no_intra_emphasis: true,
                                     fenced_code_blocks: true,
                                     strikethrough: true, underline: true)
  html = markdown.render(new_body)
  return html
end

def wrap_html(html)
  return <<HTML
<html>
<head>
<meta http-equiv="Content-Type" content="text/html charset=UTF-8" />
<meta name="generator" content="mutt-html-markdown/0.1" />
<style>
@font-face
  {font-family:Calibri;
  panose-1:2 15 5 2 2 2 4 3 2 4;}
@font-face
  {font-family:Tahoma;
  panose-1:2 11 6 4 3 5 4 4 2 4;}
p, li, div { font-size:11.0pt; font-family:"Calibri","sans-serif"; }
code { font-family: 'Andale Mono', 'Lucida Console', 'Bitstream Vera Sans Mono', 'Courier New', monospace; }
pre { border-left: 20px solid #ddd; margin-left: 10px; padding-left: 5px; }
pre.quoted { white-space: normal; border-left: 5px solid #ddd; margin-left: 0; }
</style>
</head>
<body>
#{html}
</body>
</html>
HTML
end

def process_text_part(part)
    text = part

    if @tags.include?(:markdown)
      html_text = to_markdown(part)
      html_text = wrap_html(html_text)

      if @html_only
        puts html_text
        exit 0
      end

      html_part = Mail::Part.new
      html_part.content_type = 'text/html; charset=UTF-8'
      html_part.body = html_text

      text_part = Mail::Part.new
      text_part.content_type = 'text/plain; charset=UTF-8'
      text_part.body = text.body.to_s

      bodypart = Mail::Part.new
      bodypart.text_part = text_part
      bodypart.html_part = html_part
    else
      bodypart = text
    end

    return bodypart
end

new_mail = Mail.new
new_mail.header = mail.header.to_s

new_parts = []

mail.parts.each do |part|
  if part.content_type =~ %r{^text/plain}
    bodypart = process_text_part(part)
    new_mail.add_part bodypart
  # elsif !part.filename.nil? && part.filename != ''
  else
    new_parts << part
  end
end

if mail.parts.empty?
    bodypart = process_text_part(mail)
    if mail.equal? bodypart
      new_mail.body = mail.body.to_s
    else
      new_mail.text_part = bodypart.text_part
      new_mail.html_part = bodypart.html_part
    end
end

new_parts.each do |part|
  new_mail.attachments[part.filename] = part.decoded
end

puts new_mail.to_s
