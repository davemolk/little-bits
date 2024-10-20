#!/usr/bin/env ruby

require 'fileutils'
require 'optparse'

options = {}
parser = OptionParser.new do |opts|
  opts.banner = "usage: cln [options]"
  opts.on("-sSIZE", "--size=SIZE", Integer, "size of prefix to match") { |s| options[:size] = s }
  opts.on("-eEXT", "--ext=EXT", "file extension") { |e| options[:ext] = e }
  opts.on("-pPATH", "--path=PATH", "path to files") { |p| options[:path] = p }
  opts.on("-d", "--delete", "delete files") { options[:delete] = true }
  opts.on("-h", "--help", "help") { puts opts; exit }
end
parser.parse!

[:size, :ext].each do |key|
  unless options[key]
    puts "#{key} must be included"
    puts parser
    exit 1
  end
end

pwd = options[:path] || Dir.pwd

puts "targeted files\nextension: #{options[:ext]}, prefix size: #{options[:size]}\n\n"
puts "now cleaning #{pwd}\n"

Dir.chdir(pwd)

# sort by name and date-modified (recent first)
sorted_files = Dir.glob("*.#{options[:ext]}").sort_by{ |f| [f, File.mtime(f)] }.reverse

if sorted_files.empty? 
  puts "no files found, exiting..."
  exit 0
end

deleters_dir = File.join(pwd, "delete")
FileUtils.mkdir_p(deleters_dir)

# group files by prefix length
file_groups = sorted_files.group_by { |file| File.basename(file, ".#{options[:ext]}")[0...options[:size]] }

file_groups.each do |prefix, files|
  # keep if only file in group
  next if files.size <= 1
  
  # keep first file in group
  _ = files.shift
  files.each do |file|
    FileUtils.mv(file, deleters_dir)
  end
end

puts "finished processing"

if options[:delete]
  puts "removing directories"
  FileUtils.remove_dir(deleters_dir)
end