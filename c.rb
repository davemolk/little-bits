#!/usr/bin/env ruby

require 'pathname'
require 'optparse'

def clean_cargo_in_directories(base_dir)
  curr = Pathname.new(base_dir)
  puts "examining current directory: #{curr}"
  dirs = Dir.glob("*").select { |f| File.directory?(f) }
  puts "found the following directories: #{dirs}"
  dirs.each { |d| clean_directory(curr + d) }
end

def clean_directory(directory)
  Dir.chdir(directory) do
    system "cargo clean", exception: true, out: File::NULL
  end
end

usage = <<~HELP
  usage: c <cmd>
  
  cmds:
    c         cargo clean
    cl        cargo clippy
    d         cargo doc --open
    r         cargo run
    t         cargo test
HELP

if ARGV.empty?
  puts usage
  exit 1
end

args = ARGV
args = args.map { |a| a.downcase }

case args[0]
when '-h', "--help"
  puts usage
when 'c'
  puts 'cleaning...'
  clean_cargo_in_directories(Dir.pwd)
when 'cl'
  puts 'running clippy'
  system "cargo clippy", exception: true, out: File::NULL
when 'd'
  puts 'running cargo docs --open'
  system "cargo doc --open", exception: true, out: File::NULL
when 'r'
  puts 'running...'
  system "cargo run", exception: true, out: File::NULL
when 't'
  puts 'testing...'
  system "cargo test", exception: true, out: File::NULL
else
  puts usage
  exit 1
end
