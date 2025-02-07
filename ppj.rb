#!/usr/bin/env ruby

require 'json'


input_json = ARGF.read
parsed_json = JSON.parse(input_json)
puts JSON.pretty_generate(parsed_json)