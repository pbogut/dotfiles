#!/usr/bin/env ruby
#=================================================
# name:   config.rb
# author: Pawel Bogut <https://pbogut.me>
# date:   15/12/2020
#=================================================

require 'yaml'
require 'json'
require 'erb'

class MyConfig
  @config = YAML.load(ERB.new(File.read(ENV['HOME'] + "/.config.yaml")).result)

  def self.get(key, default = nil)
    flat_cfg = flatten(@config)
    result = flat_cfg[key]

    if result.nil?
      default
    else
      result
    end
  end

  def self.flatten(config, flat_key = '', result = {})
    config.each do |key, value|
      new_key = flat_key.empty? ? key : "#{flat_key}/#{key}"
      if value.is_a? Hash
        result[new_key] = value
        flatten(value, new_key, result)
      else
        result[new_key] = value
      end
    end

    return result
  end
end

if __FILE__ == $0
  key = ARGV[0]
  default = ARGV[1]

  result = MyConfig.get(key, default)

  if result.is_a? Hash
    puts result.to_json
  else
    puts result
  end
end
