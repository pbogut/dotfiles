#!/usr/bin/ruby
#=================================================
# name:   csv.rb
# author: Pawel Bogut <pbogut@ukpos.com> <http://pbogut.me>
# date:   28/02/2017
#=================================================

require 'csv'
action = ARGV[0]

n = 0
$stdin.read.each_line do |line|
  r = CSV.parse(line)[0]
  eval action
  n = n + 1
end
