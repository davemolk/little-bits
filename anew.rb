#!/usr/bin/env ruby

require 'optparse'

options = {}
OptionParser.new do |opts| 
  opts.on("-q", "--quiet", "quiet mode") { |q| options[:quiet] = true }
  opts.on("-d", "--dry", "dry run, just dump new lines to stdout") { |d| options[:dry] = true }
  opts.on("-t", "--trim", "trim whitespace before comparing") { |t| options[:trim] = true }  
end.parse!

unless ARGV.length == 1
  warn "need a file (and only one)"
  exit 1
end

file = ARGV.shift

File.open(file, "a+") do |f|
  if f.size > 0
    f.seek(-1, IO::SEEK_END) rescue f.rewind
    last_char = f.getc
    f.puts unless last_char == "\n" || options[:dry]
  end

  f.rewind
  hash = f.each_line(chomp: true).each_with_object({}) do |line, obj|
    line = line.strip if options[:trim]
    obj[line] = true unless line.empty?
  end

  while (line = gets)
    clean_line = line.chomp
    clean_line = clean_line.strip if options[:trim]
    unless hash[clean_line]
      f.puts clean_line unless options[:dry]
      puts clean_line unless options[:quiet]
      hash[clean_line] = true
    end
  end
end
