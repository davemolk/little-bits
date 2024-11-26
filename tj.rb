#!/usr/bin/env ruby

require 'json'
require 'optparse'


def to_array(input)
  input.each_line.map(&:chomp)
end

def to_2d(input)
  input.each_line.map { |line| line.split }
end

def to_map(input, keys)
  input.each_line.map do |line|
    values = line.split
    keys.zip(values).each_with_object({}) do |(key, value), hash|
      next if key == '-'
      hash[key] = value
    end
  end
end

options = { format: 'array' }
OptionParser.new do |opts| 
  opts.banner = "usage: tj [options]"

  opts.on("-f", "--format FORMAT", "output format to use (array, 2d, map)") do |format|
    options[:format] = format
  end
end.parse!

input = $stdin

case options[:format]
when '2d'
  puts JSON.pretty_generate(to_2d(input))
when 'map'
  puts JSON.pretty_generate(to_map(input, ARGV))
else
  puts JSON.pretty_generate(to_array(input))
end

