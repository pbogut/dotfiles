#!/usr/bin/env ruby
#=================================================
# name:   aspell.rb
# author: Pawel Bogut <http://pbogut.me>
# date:   16/01/2017
#=================================================

require 'open3'

ARGV.each do |file|
  index = 0
  File.foreach(file) do |line|
    o, _, _ = Open3.capture3('aspell -a --run-together --run-together-min=10', stdin_data: line)
    index += 1
    o.each_line do |line|
      # next if line.match(/^\@|^\*/)
      # next if line.strip.empty?
      text = line.gsub(/^& (.*) \d+ (\d+):.*/, '\1')
      next if text == line
      text.strip!
      puts "#{file}:#{index}: '#{text}' was not found in the dictionary (from token '#{text}')"
    end
  end
end
exit 1
