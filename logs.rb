#!/usr/bin/env ruby

require 'optparse'
require File.expand_path('io_utils.rb', File.dirname(__FILE__))

def help
  puts <<~HELP
    usage: logs <codebase> [options]
    -n, --namespace   which namespace
    -d, --dry         print, don't copy to clipboard
    -h, --help        this!
  HELP
end

def gc(name, extra)
  cmd = "kubectl -n gcdev#{name} logs deployment/hub"
  extra ? cmd += " #{extra}" : cmd += " -f" 
  return cmd
end

def gm(extra)
  cmd = "journalctl -u galaxy-migrate"
  cmd += " #{extra}" if extra
  return cmd
end

def customer(extra)
  cmd = "docker logs cportal-server"
  extra.nil? ? cmd += " -f" : cmd += " #{extra}" 
  return cmd
end

options = {}
OptionParser.new do |opts|
  opts.on("-h", "--help", "display help") { help; exit 0 }
  opts.on("-n=NAME", "--namespace=NAME", "namespace") { |n| options[:name] = n }
  opts.on("-d", "--dry", "print command, don't copy to clipboard") { options[:dry] = true }
  opts.on("-e=EXTRA", "--extra=EXTRA", "extra stuff") { |e| options[:extra] = e }
end.parse!

if ARGV.empty?
  warn "needs a codebase:\ngc, gm, c"
  exit 1
end

cmd = ''
case ARGV[0]
when "gc" then cmd = gc(options[:name], options[:extra])
when "gm" then cmd = gm(options[:extra])
when "c" then cmd = customer(options[:extra])
else
  warn "invalid choice: pick from gc, gm, c"
  exit 1
end

if options[:dry] 
  puts cmd
else
  IoUtils.copy_to_clipboard(cmd)
end
