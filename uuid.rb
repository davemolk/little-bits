#!/usr/bin/env ruby

require File.expand_path('io_utils.rb', File.dirname(__FILE__))
require 'optparse'
require 'open3'

def help
  puts <<~HELP
    usage uuid [option]

    generate a uuid. copies to clipboard by default
    (print to stdout instead with -p or --print)
  HELP
end

options = {
  copy: true,
}
OptionParser::new do |opts| 
  opts.on("-h", "--help", "print help") { puts help; exit }
  opts.on("-p", "--print", "print uuid to stdout") { options[:copy] = false }
end.parse!

uuid, status = Open3.capture2("uuidgen")
if !status.success?
  warns "bad status: #{status}"
  exit 1
end

if options[:copy] 
  IoUtils.copy_to_clipboard(uuid, new_line = false)
else
  puts uuid
end 